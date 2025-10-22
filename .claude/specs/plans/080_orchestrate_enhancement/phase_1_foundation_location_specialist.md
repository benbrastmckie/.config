# Phase 1: Foundation - Location Specialist and Artifact Organization

## Metadata
- **Plan**: 080_orchestrate_enhancement
- **Phase Number**: 1
- **Phase Name**: Foundation - Location Specialist and Artifact Organization
- **Complexity**: 7/10 (Medium-High)
- **Parent Plan**: [080_orchestrate_enhancement.md](../080_orchestrate_enhancement.md)
- **Expansion Reason**: Cross-phase coordination, artifact path injection, and foundation-setting nature requiring detailed implementation specifications

## Objective

Implement Phase 0 (Project Location Determination) with location-specialist agent and enforce artifact organization across all phases of the /orchestrate workflow. This phase establishes the foundation for all subsequent phases by ensuring artifacts are created in the correct topic-based directory structure (`specs/NNN_topic/`) and that all subagents receive proper artifact path context through [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md).

## Revision History

### 2025-10-21 - Revision 1: Expanded Phase 1 Scope
**Changes**: Added two new stages (Stage 6 and Stage 7) to complete Phase 1 fully
**Reason**: Initial implementation (Stages 1-4) left debug and documentation phases incomplete. To fully complete Phase 1 foundation work before proceeding to Phases 3-5, debug loop and documentation phase artifact injection must be implemented.
**Modified Stages**:
- Stage 5: Marked as SKIPPED (inline validation sufficient)
- Stage 6: ✅ COMPLETED - Implement Debug Loop with Artifact Path Injection (Complexity: 8/10)
- Stage 7: ✅ COMPLETED - Update Documentation Phase with Artifact Path Injection (Complexity: 4/10)

**Total New Work**: 2 stages, ~4-6 hours implementation
**Benefits**: Phase 1 fully complete, debug workflow testable end-to-end, all artifact organization patterns consistent

## Dependencies

- **depends_on**: [phase_0] - CRITICAL: Command-to-command invocation removal MUST be complete before [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) WILL work
- **blocks**: [phase_2, phase_3, phase_4, phase_5, phase_6, phase_7] - All subsequent phases require artifact organization foundation

## Architecture Overview

### Topic-Based Directory Structure

The location-specialist establishes the following structure for each orchestrated workflow:

```
specs/NNN_topic/
├── reports/         # Research phase outputs (gitignored except debug/)
│  ├── NNN_research_1.md
│  ├── NNN_research_2.md
│  └── NNN_research_overview.md
├── plans/          # Planning phase outputs (gitignored)
│  └── NNN_plan_name.md
│    └── NNN_plan_name/  # Created if plan expanded (Level 1+)
│      ├── phase_1_*.md
│      └── phase_2_*/  # Created if phase expanded (Level 2)
├── summaries/        # Documentation phase outputs (gitignored)
│  └── NNN_workflow_summary.md
├── debug/          # Debug phase outputs (COMMITTED - critical for issue tracking)
│  └── NNN_debug_report.md
├── scripts/         # Temporary scripts during implementation (gitignored)
│  └── NNN_temp_script.sh
└── outputs/         # Test results and build artifacts (gitignored)
  ├── test_results.txt
  └── coverage/
```

### [[Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md)](../../../docs/concepts/patterns/behavioral-injection.md)

The location-specialist returns a **location context object** that is injected into all subsequent subagent prompts:

```yaml
location_context:
 topic_path: "/absolute/path/to/specs/027_authentication/"
 topic_number: "027"
 topic_name: "authentication"
 artifact_paths:
  reports: "{topic_path}/reports/"
  plans: "{topic_path}/plans/"
  summaries: "{topic_path}/summaries/"
  debug: "{topic_path}/debug/"
  scripts: "{topic_path}/scripts/"
  outputs: "{topic_path}/outputs/"
 project_root: "/absolute/path/to/project/"
 specs_root: "/absolute/path/to/project/specs/"
```

This context is then injected into every subagent prompt with explicit save instructions:

```
Research Subagent Prompt:
 ...
 ARTIFACT ORGANIZATION (CRITICAL):
 - Save all reports to: /absolute/path/to/specs/027_authentication/reports/
 - Use topic number 027 in filenames: 027_research_oauth.md
 - Follow naming convention: {topic_num}_{descriptive_name}.md
 ...
```

## Stage Breakdown

### Stage 1: Create location-specialist Agent

**Objective**: Implement the location-specialist agent with directory analysis, topic numbering, and structure creation logic.

**Complexity**: Medium (5/10)

**Tasks**:

- [ ] Create location-specialist agent file at `.claude/agents/location-specialist.md`
 - Define agent role: "Project location analyzer and topic directory creator"
 - Document behavioral guidelines following agent template patterns
 - Include constraints: Read-only analysis, write operations only for directory creation

- [ ] Implement workflow request analysis logic
 - Agent must parse user's workflow description to identify affected components
 - Extract keywords: feature names, module names, file paths mentioned
 - Example: "Add OAuth authentication to user service" → identifies: authentication, user service, OAuth
 - Search codebase for mentioned components using Grep tool
 - Identify all files related to the workflow request

- [ ] Implement deepest common parent directory detection
 - Given list of affected files, find deepest directory containing all
 - Algorithm:
  ```bash
  # Pseudocode for directory detection
  affected_files=["src/auth/oauth.ts", "src/auth/jwt.ts", "tests/auth/oauth.test.ts"]

  # Extract unique directories
  dirs=["src/auth", "src/auth", "tests/auth"]

  # Find common parent
  common_parent="." # Start with project root

  # For each directory, find deepest common path
  for dir in dirs:
   common_parent = find_common_path(common_parent, dir)

  # Result: "." (project root, since src/ and tests/ diverge)
  # specs/ location: "./specs/"
  ```
 - Fallback: If no files mentioned, use project root

- [ ] Implement topic number determination
 - List existing topic directories in determined specs/ location
 - Parse directory names: `specs/NNN_topic_name/` → extract NNN
 - Find maximum existing number: `max(001, 027, 042) → 042`
 - Calculate next number: `042 + 1 = 043` with zero-padding
 - Handle edge cases:
  - No existing topics → start at `001`
  - Number gaps (e.g., 001, 003, 005) → use max + 1 = 006
  - Collisions: If 043 already exists during creation, retry with 044

- [ ] Implement topic directory structure creation
 - Create base directory: `mkdir -p {specs_root}/{topic_num}_{topic_name}/`
 - Create subdirectories using single command:
  ```bash
  mkdir -p {topic_path}/{reports,plans,summaries,debug,scripts,outputs}
  ```
 - Verify all directories created successfully
 - Handle permission errors gracefully with error messages

- [ ] Implement location context object generation
 - Construct context object with all required fields
 - Use absolute paths (CRITICAL: subagents need absolute paths, not relative)
 - Generate topic name from workflow description (sanitize, lowercase, underscores)
 - Return context as structured YAML for easy parsing

- [ ] Add validation and error handling
 - Verify specs/ directory exists, create if missing
 - Check write permissions before directory creation
 - Validate topic number uniqueness before finalizing
 - Error responses:
  ```yaml
  error:
   type: "permission_denied"
   message: "Cannot write to specs/ directory"
   recovery: "Check directory permissions or run with appropriate access"
  ```

**Testing**:

```bash
# Test location-specialist agent directly
# Simulate orchestrate calling location-specialist

# Test Case 1: Simple workflow in existing codebase
Task {
 subagent_type: "general-purpose"
 description: "Determine project location for authentication workflow"
 prompt: |
  You are a location-specialist agent.

  Workflow request: "Add OAuth authentication to user service"
  Project root: /home/benjamin/.config

  Tasks:
  1. Analyze request to identify affected components (OAuth, authentication, user service)
  2. Search codebase for related files
  3. Find deepest common parent directory
  4. Determine next topic number in specs/
  5. Create topic directory: specs/NNN_authentication/
  6. Return location context object
}

# Expected output:
location_context:
 topic_path: "/home/benjamin/.config/specs/081_authentication/"
 topic_number: "081"
 topic_name: "authentication"
 artifact_paths:
  reports: "/home/benjamin/.config/specs/081_authentication/reports/"
  plans: "/home/benjamin/.config/specs/081_authentication/plans/"
  ...
 project_root: "/home/benjamin/.config/"
 specs_root: "/home/benjamin/.config/specs/"

# Verify directories created
ls -la /home/benjamin/.config/specs/081_authentication/
# Expected: reports/ plans/ summaries/ debug/ scripts/ outputs/
```

**Expected Outcomes**:
- location-specialist agent file created with complete implementation
- Directory analysis logic correctly identifies affected components
- Topic numbering handles all edge cases (no topics, gaps, collisions)
- Directory creation succeeds with proper error handling
- Location context object has all required fields with absolute paths

---

### Stage 2: Integrate location-specialist into orchestrate.md Phase 0

**Objective**: Add Phase 0 to orchestrate.md workflow that invokes location-specialist and stores context for injection into subsequent phases.

**Complexity**: Medium (6/10)

**Tasks**:

- [ ] Add Phase 0 section to orchestrate.md before research phase
 - Insert new phase: "Phase 0: Project Location Determination"
 - Add TodoWrite task for Phase 0
 - Document phase objective and complexity

- [ ] Implement location-specialist invocation
 - Use Task tool (NOT SlashCommand - per Phase 0 requirements)
 - Construct subagent prompt with workflow request
 - Pass project root from environment
 - Example invocation:
  ```yaml
  Task {
   subagent_type: "general-purpose"
   description: "Determine project location and create topic directory structure"
   prompt: |
    Read and follow the behavioral guidelines from:
    /home/benjamin/.config/.claude/agents/location-specialist.md

    You are acting as a location-specialist agent.

    OPERATION: Analyze workflow request and establish artifact organization

    Context:
     - Workflow request: "{user_workflow_description}"
     - Project root: "{project_root_from_env}"
     - Current working directory: "{cwd}"

    Tasks:
     1. Analyze workflow request to identify affected components
     2. Search codebase for related files using Grep/Glob tools
     3. Find deepest common parent directory
     4. Determine next topic number in specs/
     5. Create topic directory structure: specs/NNN_topic/{reports,plans,summaries,debug,scripts,outputs}/
     6. Return location context object with absolute paths

    Required output format (YAML):
     location_context:
      topic_path: "..."
      topic_number: "..."
      topic_name: "..."
      artifact_paths:
       reports: "..."
       plans: "..."
       summaries: "..."
       debug: "..."
       scripts: "..."
       outputs: "..."
      project_root: "..."
      specs_root: "..."
  }
  ```

- [ ] Extract location context from subagent response
 - Parse YAML response from location-specialist
 - Validate all required fields present
 - Store in workflow state variable: `LOCATION_CONTEXT`
 - Handle extraction errors:
  ```bash
  if ! parse_yaml_response "$LOCATION_SPECIALIST_OUTPUT"; then
   error "Failed to extract location context from location-specialist"
   # Fallback: Use project root with default topic number
  fi
  ```

- [ ] Store location context in workflow state
 - Create workflow state object to carry context between phases
 - Example workflow state structure:
  ```yaml
  workflow_state:
   phase: 0
   location_context: { ... } # From location-specialist
   research_reports: []    # Will be populated in Phase 1
   overview_report: null    # Will be populated in Phase 2
   plan_path: null       # Will be populated in Phase 2
   complexity_report: null   # Will be populated in Phase 3
   ...
  ```
 - Persist state for cross-phase access

MANDATORY VERIFICATION CHECKPOINT:
```bash
# Verify topic directory structure was created
TOPIC_PATH="${LOCATION_CONTEXT[topic_path]}"
if [ ! -d "$TOPIC_PATH" ]; then
  echo "ERROR: Topic directory not created at $TOPIC_PATH"
  echo "FALLBACK: location-specialist failed - creating directory structure manually"
  mkdir -p "$TOPIC_PATH"/{reports,plans,summaries,debug,scripts,outputs}
fi

# Verify all required subdirectories exist
for subdir in reports plans summaries debug scripts outputs; do
  if [ ! -d "$TOPIC_PATH/$subdir" ]; then
    echo "WARNING: Missing subdirectory $TOPIC_PATH/$subdir - creating"
    mkdir -p "$TOPIC_PATH/$subdir"
  fi
done

echo "Verification complete: Topic directory structure validated at $TOPIC_PATH"
```
End verification. Proceed only if directory structure exists.

- [ ] Add validation after Phase 0 completion
 - Verify topic directory exists
 - Verify all subdirectories created
 - Verify location_context has absolute paths
 - Display Phase 0 summary to user:
  ```
  ✓ Phase 0: Project Location Determination Complete

  Topic: 027_authentication
  Location: /home/benjamin/.config/specs/027_authentication/
  Artifact Paths:
   - Reports: specs/027_authentication/reports/
   - Plans: specs/027_authentication/plans/
   - Summaries: specs/027_authentication/summaries/
   - Debug: specs/027_authentication/debug/ (committed)

  Next: Phase 1 - Research
  ```

- [ ] Add Phase 0 completion checkpoint
 - Mark Phase 0 as complete in TodoWrite
 - Update workflow state: phase = 1
 - Prepare for Phase 1 (Research) with location context ready

**Testing**:

```bash
# Test Phase 0 integration in orchestrate.md
/orchestrate "Add logging to authentication module"

# Verify Phase 0 output displayed
# Expected: Topic directory created, location context stored

# Verify workflow state contains location_context
# Expected: All artifact paths present and absolute

# Verify subsequent phases WILL access location_context
# Expected: Phase 1 (Research) receives artifact paths for injection
```

**Expected Outcomes**:
- Phase 0 successfully added to orchestrate.md workflow
- location-specialist invoked using Task tool (not SlashCommand)
- Location context extracted and stored in workflow state
- Validation confirms directory structure created correctly
- User sees Phase 0 summary with topic information

---

### Stage 3: Inject Artifact Paths into Research Phase

**Objective**: Modify Research phase (Phase 1) to inject artifact paths from location context into research-specialist subagent prompts, ensuring research reports are saved to correct location.

**Complexity**: Medium (6/10)

**Tasks**:

- [ ] Update research-specialist prompt template in orchestrate.md
 - Locate existing research-specialist invocation (Phase 1)
 - Add artifact path injection section to prompt:
  ```yaml
  Research Task Prompt:
   Context:
    - Research topic: "{topic}"
    - Workflow request: "{user_request}"
    - Project root: "{project_root}"

   ARTIFACT ORGANIZATION (CRITICAL - MUST FOLLOW):
    - Save ALL reports to: {location_context.artifact_paths.reports}
    - Filename format: {location_context.topic_number}_research_{topic_name}.md
    - Example: 027_research_oauth_patterns.md
    - Use absolute path: {location_context.artifact_paths.reports}027_research_oauth_patterns.md
    - DO NOT save to arbitrary locations
    - DO NOT use relative paths

   Research Requirements:
    - Comprehensive analysis of {topic}
    - Code examples from project codebase
    - Best practices and recommendations
    - Save report to specified artifact path
  ```

- [ ] Inject location context into all parallel research agents
 - Modify parallel research invocation to pass location_context to each agent
 - Currently: 4 parallel research agents in orchestrate.md
 - Update: All 4 agents receive same artifact_paths.reports
 - Example multi-agent invocation:
  ```yaml
  # Invoke 4 research agents in parallel
  for topic in research_topics:
   Task {
    subagent_type: "general-purpose"
    description: "Research {topic}"
    prompt: |
     ... research prompt ...

     ARTIFACT ORGANIZATION:
      - Save report to: {location_context.artifact_paths.reports}{topic_num}_research_{topic}.md

     ... rest of prompt ...
   }
  ```

- [ ] Add artifact path validation after research phase
 - After all research agents complete, verify reports created in correct location
 - Check each report path returned by research agents
 - Validation logic:
  ```bash
  for report_path in research_report_paths:
   if [[ "$report_path" != "$LOCATION_CONTEXT_REPORTS_PATH"* ]]; then
    warn "Report created in wrong location: $report_path"
    warn "Expected location: $LOCATION_CONTEXT_REPORTS_PATH"

    # Fallback: Move report to correct location
    filename=$(basename "$report_path")
    correct_path="$LOCATION_CONTEXT_REPORTS_PATH$filename"
    mv "$report_path" "$correct_path"
    log "Moved report to correct location: $correct_path"
   fi
  done
  ```

- [ ] Update research phase to include topic number in filenames
 - Ensure all research reports use topic number prefix
 - Naming convention: `{NNN}_research_{descriptive_name}.md`
 - Example: `027_research_oauth_patterns.md`, `027_research_jwt_security.md`
 - Pass topic number to research agents: `{location_context.topic_number}`

- [ ] Add fallback for misplaced artifacts
 - Detect reports created outside artifact_paths.reports
 - Log warning with misplaced path
 - Automatically move to correct location
 - Report correction to user:
  ```
  ⚠ Warning: Research report created in wrong location
  Original: /home/user/project/oauth_research.md
  Moved to: /home/user/project/specs/027_authentication/reports/027_research_oauth_patterns.md
  ```

- [ ] Update workflow state with research report paths
 - Store corrected report paths in workflow_state.research_reports
 - Ensure all paths are absolute
 - Prepare for Phase 2 (Research Synthesis) consumption

**Testing**:

```bash
# Test research phase artifact injection
/orchestrate "Research OAuth best practices and JWT security patterns"

# Verify research agents receive artifact paths
# Expected: Prompts include "Save report to: specs/027_authentication/reports/"

# Verify reports created in correct location
ls specs/027_authentication/reports/
# Expected: 027_research_oauth_best_practices.md, 027_research_jwt_security_patterns.md

# Test misplaced artifact detection
# Manually create report in wrong location
echo "test" > /tmp/wrong_location.md
# Simulate research agent returning wrong path
# Verify: Fallback moves file to correct location and logs warning

# Verify workflow state contains correct paths
# Expected: workflow_state.research_reports = [absolute paths in reports/ dir]
```

**Expected Outcomes**:
- Research phase prompts successfully inject artifact paths
- All research reports created in `{topic_path}/reports/` directory
- Reports use topic number prefix in filenames
- Artifact path validation detects and corrects misplaced files
- Workflow state contains correct absolute paths for Phase 2

---

### Stage 4: Inject Artifact Paths into Planning and Debug Phases

**Objective**: Modify Planning phase (Phase 2) and Debug phase (Phase 5) to inject artifact paths, ensuring plans and debug reports are saved to correct topic-based locations.

**Complexity**: Medium (6/10)

**Tasks**:

- [ ] Update plan-architect prompt template in orchestrate.md
 - Locate planning phase invocation (Phase 2, after Phase 0 refactor)
 - Add artifact path injection for plan save location:
  ```yaml
  Planning Task Prompt:
   Context:
    - Feature description: "{user_request}"
    - Research overview: "{overview_report_path}" # From Phase 2 (Research Synthesis)
    - Project standards: "{CLAUDE_MD_path}"

   ARTIFACT ORGANIZATION (CRITICAL):
    - Save plan to: {location_context.artifact_paths.plans}{topic_number}_{plan_name}.md
    - Filename format: {topic_number}_{descriptive_plan_name}.md
    - Example: 027_authentication_implementation.md
    - Use absolute path: {location_context.artifact_paths.plans}027_authentication_implementation.md
    - DO NOT save to arbitrary locations

   Plan Requirements:
    - Multi-phase structure with dependencies
    - Testing strategy per phase
    - /implement compatibility
    - Include metadata section with topic number and complexity scores
  ```

- [ ] Inject topic number into plan metadata
 - plan-architect MUST include topic number in plan metadata section
 - Example metadata section to inject:
  ```markdown
  ## Metadata
  - **Date**: 2025-10-21
  - **Topic Number**: 027
  - **Topic Path**: /absolute/path/to/specs/027_authentication/
  - **Feature**: Authentication implementation with OAuth and JWT
  - **Estimated Phases**: 5
  ```
 - Pass topic number and path explicitly: `{location_context.topic_number}`, `{location_context.topic_path}`

- [ ] Update debug-specialist prompt template in orchestrate.md
 - Locate debug phase invocation (Phase 5 in enhanced workflow, after Testing phase)
 - Add artifact path injection for debug reports:
  ```yaml
  Debug Task Prompt:
   Context:
    - Test failures: "{failed_test_details}" # From Phase 4 (Testing)
    - Implementation files: "{files_modified}" # From Phase 3 (Implementation)
    - Plan path: "{plan_path}"

   ARTIFACT ORGANIZATION (CRITICAL):
    - Save debug report to: {location_context.artifact_paths.debug}{topic_number}_debug_report.md
    - Filename format: {topic_number}_debug_{issue_description}.md
    - Example: 027_debug_oauth_token_validation_failure.md
    - Use absolute path
    - NOTE: Debug reports are COMMITTED (not gitignored) for issue tracking

   Debug Requirements:
    - Analyze test failures and identify root causes
    - Propose specific fixes with code examples
    - Include reproduction steps
    - Rate confidence level in proposed fixes
  ```

- [ ] Add special handling for debug reports (committed, not gitignored)
 - Document in orchestrate.md that debug reports go in debug/ subdirectory
 - Note that debug/ is committed (unlike reports/, plans/, summaries/)
 - Rationale: Debug reports critical for issue tracking and future reference
 - Add comment in prompt:
  ```yaml
  # IMPORTANT: Debug reports are saved to {topic_path}/debug/ and are COMMITTED
  # Unlike other artifacts (reports/, plans/, summaries/), debug reports provide
  # critical issue tracking information and MUST be version controlled.
  ```

- [ ] Add validation for plan and debug report paths
 - After plan-architect completes, verify plan saved to artifact_paths.plans
 - After debug-specialist completes, verify debug report saved to artifact_paths.debug
 - Validation logic similar to research phase:
  ```bash
  # Validate plan path
  if [[ "$plan_path" != "$LOCATION_CONTEXT_PLANS_PATH"* ]]; then
   warn "Plan created in wrong location: $plan_path"
   correct_path="$LOCATION_CONTEXT_PLANS_PATH$(basename "$plan_path")"
   mv "$plan_path" "$correct_path"
   plan_path="$correct_path"
  fi

  # Validate debug report path
  if [[ "$debug_report_path" != "$LOCATION_CONTEXT_DEBUG_PATH"* ]]; then
   warn "Debug report created in wrong location: $debug_report_path"
   correct_path="$LOCATION_CONTEXT_DEBUG_PATH$(basename "$debug_report_path")"
   mv "$debug_report_path" "$correct_path"
   debug_report_path="$correct_path"
  fi
  ```

- [ ] Update workflow state with plan and debug report paths
 - Store plan_path in workflow_state after Planning phase
 - Store debug_report_path in workflow_state after Debug phase (if invoked)
 - Ensure paths are absolute and validated

**Testing**:

```bash
# Test planning phase artifact injection
/orchestrate "Implement authentication with OAuth and JWT"

# Verify plan created in correct location
ls specs/NNN_authentication/plans/
# Expected: NNN_authentication_implementation.md

# Verify plan metadata includes topic number
grep "Topic Number" specs/NNN_authentication/plans/NNN_authentication_implementation.md
# Expected: - **Topic Number**: NNN

# Test debug phase artifact injection (simulate test failure to trigger debug)
# ... implementation phase completes ...
# ... testing phase fails with test errors ...
# ... debug phase invoked ...

# Verify debug report created in correct location
ls specs/NNN_authentication/debug/
# Expected: NNN_debug_oauth_token_validation_failure.md

# Verify debug report is in committed directory (not gitignored)
git status specs/NNN_authentication/debug/
# Expected: debug/ directory changes shown (not ignored)

# Verify fallback moves misplaced files
# Test by simulating plan created in wrong location
# Expected: File moved to correct location with warning logged
```

**Expected Outcomes**:
- Planning phase injects artifact paths successfully
- Plans created in `{topic_path}/plans/` with topic number prefix
- Plan metadata includes topic number and path
- Debug phase injects artifact paths successfully
- Debug reports created in `{topic_path}/debug/` (committed directory)
- Path validation detects and corrects misplaced files
- Workflow state contains validated absolute paths

---

### Stage 5: Implement Artifact Validation and Fallback [SKIPPED]

**Status**: SKIPPED - Inline validation sufficient
**Rationale**: Stages 2-4 already include inline validation checkpoints after each phase. Creating a separate validation utility adds unnecessary abstraction. Inline validation provides immediate feedback and automatic fallback without additional function call overhead.

**Complexity**: Medium (5/10) - Not implemented

**Tasks**:

- [ ] Create artifact validation utility function
 - Function: `validate_artifact_location(artifact_path, expected_location, artifact_type)`
 - Parameters:
  - `artifact_path`: Actual path returned by subagent
  - `expected_location`: Location from location_context (e.g., artifact_paths.reports)
  - `artifact_type`: Type for logging (e.g., "research report", "plan", "debug report")
 - Implementation:
  ```bash
  validate_artifact_location() {
   local artifact_path="$1"
   local expected_location="$2"
   local artifact_type="$3"

   # Check if artifact exists
   if [[ ! -f "$artifact_path" ]]; then
    error "Artifact not found: $artifact_path"
    return 1
   fi

   # Check if artifact is in expected location
   if [[ "$artifact_path" != "$expected_location"* ]]; then
    warn "⚠ $artifact_type created in wrong location"
    warn " Actual: $artifact_path"
    warn " Expected: $expected_location"

    # Move to correct location
    filename=$(basename "$artifact_path")
    correct_path="${expected_location}${filename}"

    if mv "$artifact_path" "$correct_path"; then
     log "✓ Moved $artifact_type to correct location: $correct_path"
     echo "$correct_path" # Return corrected path
     return 0
    else
     error "Failed to move $artifact_type to correct location"
     return 1
    fi
   else
    log "✓ $artifact_type in correct location: $artifact_path"
    echo "$artifact_path" # Return validated path
    return 0
   fi
  }
  ```

- [ ] Add validation calls after each phase in orchestrate.md
 - After Research phase (Phase 1):
  ```bash
  # Validate all research reports
  for report_path in "${research_report_paths[@]}"; do
   corrected_path=$(validate_artifact_location \
    "$report_path" \
    "$LOCATION_CONTEXT_REPORTS_PATH" \
    "research report")

   # Update workflow state with corrected path
   research_reports+=("$corrected_path")
  done
  ```

 - After Planning phase (Phase 2):
  ```bash
  # Validate plan path
  plan_path=$(validate_artifact_location \
   "$plan_path" \
   "$LOCATION_CONTEXT_PLANS_PATH" \
   "implementation plan")

  # Update workflow state
  workflow_state[plan_path]="$plan_path"
  ```

 - After Debug phase (Phase 5, if invoked):
  ```bash
  # Validate debug report path
  debug_report_path=$(validate_artifact_location \
   "$debug_report_path" \
   "$LOCATION_CONTEXT_DEBUG_PATH" \
   "debug report")
  ```

- [ ] Add comprehensive artifact organization report at workflow end
 - After all phases complete, display artifact summary:
  ```
  ✓ Workflow Complete: Authentication Implementation

  Artifact Organization Summary:
  Topic: 027_authentication
  Location: /home/benjamin/.config/specs/027_authentication/

  Research Reports (4):
   ✓ specs/027_authentication/reports/027_research_oauth_patterns.md
   ✓ specs/027_authentication/reports/027_research_jwt_security.md
   ✓ specs/027_authentication/reports/027_research_session_management.md
   ✓ specs/027_authentication/reports/027_research_overview.md

  Implementation Plan:
   ✓ specs/027_authentication/plans/027_authentication_implementation.md

  Workflow Summary:
   ✓ specs/027_authentication/summaries/027_workflow_summary.md

  Debug Reports (1):
   ✓ specs/027_authentication/debug/027_debug_oauth_token_validation.md (committed)

  All artifacts organized correctly ✓
  ```

- [ ] Add logging for artifact organization metrics
 - Track artifacts moved vs correctly placed
 - Log warnings if >25% of artifacts misplaced (indicates prompt injection issue)
 - Example metrics:
  ```
  Artifact Organization Metrics:
  - Total artifacts: 7
  - Correctly placed: 6 (86%)
  - Moved to correct location: 1 (14%)
  - Failed to move: 0 (0%)

  ⚠ Note: 14% of artifacts were misplaced and corrected automatically.
  Consider reviewing subagent prompt injection if this rate is high.
  ```

- [ ] Add artifact organization validation to workflow completion criteria
 - Workflow not considered complete until all artifacts validated
 - If validation fails, report to user and suggest manual correction
 - Example completion check:
  ```bash
  # Final validation before workflow completion
  all_artifacts_valid=true

  for artifact in all_workflow_artifacts; do
   if ! validate_artifact_location "$artifact" ...; then
    all_artifacts_valid=false
   fi
  done

  if [[ "$all_artifacts_valid" == false ]]; then
   warn "⚠ Some artifacts were not validated or moved"
   warn "Please review artifact locations manually"
   # Still complete workflow, but with warning
  fi
  ```

**Testing**:

```bash
# Test artifact validation with correctly placed artifacts
/orchestrate "Simple workflow with correct artifact placement"
# Verify: All artifacts validated successfully, no warnings

# Test artifact validation with misplaced artifacts
# Simulate research agent creating report in wrong location
# Expected: Artifact detected as misplaced, moved automatically, warning logged

# Test validation with missing artifact
# Simulate subagent returning path to non-existent file
# Expected: Error logged, workflow fails gracefully with clear error message

# Test artifact organization summary display
/orchestrate "Complete workflow"
# Verify: Summary displayed at end with all artifact paths listed

# Test artifact organization metrics
# Simulate workflow with 3/10 artifacts misplaced
# Expected: Metrics show 70% correct, 30% moved, warning about high misplacement rate
```

**Expected Outcomes**:
- Artifact validation utility function works for all artifact types
- Validation runs after every phase, correcting misplaced files
- Artifact organization summary displayed at workflow end
- Metrics track artifact placement success rate
- High misplacement rate triggers warning for prompt review
- Workflow completion criteria includes artifact validation

---

### Stage 6: Implement Debug Loop with Artifact Path Injection

**Objective**: Implement the conditional debugging loop within the Implementation Phase with Task invocation for debug-analyst agent and artifact path injection from Phase 0 location context.

**Complexity**: High (8/10) - Conditional logic, iteration control, escalation handling

**Tasks**:

- [ ] Add debug loop logic to Implementation Phase (orchestrate.md)
  - **YOU MUST locate** Implementation Phase section (lines ~2140-2260)
  - **EXECUTE NOW**: Implement test failure detection after code-writer completion
  - **YOU WILL add** conditional check: `if tests_passing == false then enter_debugging_loop`
  - **YOU MUST initialize** debug iteration counter (max 3 iterations)
  - **EXECUTE NOW**: Generate debug topic slug from error message
  - Example slug generation:
    ```bash
    # Extract error type from test output
    ERROR_MSG="auth_spec.lua:42 - Expected 200, got 401"
    DEBUG_SLUG=$(echo "$ERROR_MSG" | sed 's/.*: //' | tr ' ' '_' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]//g')
    # Result: "expected_200_got_401" or "auth_status_code"
    ```

- [ ] Create debug-analyst Task invocation template
  - **CRITICAL**: Use Task tool with general-purpose subagent (NOT SlashCommand per Phase 0 requirements)
  - **YOU MUST inject** behavioral guidelines from `.claude/agents/debug-analyst.md`
  - **YOU WILL pass** test failure context to agent
  - **EXECUTE NOW**: Create template with this exact structure:
    ```yaml
    Task {
      subagent_type: "general-purpose"
      description: "Investigate test failure and create debug report"
      timeout: 300000  # 5 minutes for investigation
      prompt: |
        Read and follow the behavioral guidelines from:
        ${CLAUDE_PROJECT_DIR}/.claude/agents/debug-analyst.md

        You are acting as a Debug Analyst Agent.

        OPERATION: Investigate test failure and propose fix

        Context:
         - Issue: ${FAILED_TEST_ERROR_MESSAGE}
         - Failed tests: ${FAILED_TEST_LIST}
         - Modified files: ${FILES_MODIFIED}
         - Test output file: ${ARTIFACT_OUTPUTS}test_failures.txt
         - Hypothesis: ${DEBUG_HYPOTHESIS}
         - Project standards: ${CLAUDE_PROJECT_DIR}/CLAUDE.md

        ARTIFACT ORGANIZATION (CRITICAL - From Phase 0 Location Context):
         - Save debug report to: ${ARTIFACT_DEBUG}
         - Filename format: ${TOPIC_NUMBER}_debug_${DEBUG_SLUG}.md
         - Example: 027_debug_oauth_token_validation.md
         - Full absolute path: ${ARTIFACT_DEBUG}${TOPIC_NUMBER}_debug_${DEBUG_SLUG}.md
         - DO NOT use relative paths
         - DO NOT save to arbitrary locations
         - NOTE: Debug reports are COMMITTED (not gitignored) for issue tracking

        Investigation Requirements:
         - Reproduce test failure if possible
         - Analyze root cause with evidence
         - Propose specific fix with code examples and line numbers
         - Assess impact and fix complexity
         - Return metadata only (not full report content)

        RETURN FORMAT:
        DEBUG_REPORT_CREATED: [absolute path to debug report]

        Root Cause Summary (50 words max):
        [concise summary of findings]
    }
    ```

- [ ] Inject artifact paths from Phase 0 location context
  - `${ARTIFACT_DEBUG}` - Debug reports directory (from location_context.artifact_paths.debug)
  - `${ARTIFACT_OUTPUTS}` - Test output files (from location_context.artifact_paths.outputs)
  - `${ARTIFACT_SCRIPTS}` - Temporary debug scripts (from location_context.artifact_paths.scripts)
  - `${TOPIC_NUMBER}` - Topic number for filename prefix (from location_context.topic_number)
  - **YOU MUST ensure** all paths are absolute
  - **MANDATORY**: Validate location_context exists before debug loop

- [ ] Parse debug-analyst response and extract metadata
  - **EXECUTE NOW**: Extract debug report path from agent response
  - **YOU MUST extract** 50-word root cause summary
  - **MANDATORY VERIFICATION**: Validate report file exists at specified path
  - **YOU WILL store** report path in workflow_state.debug_reports array
  - Example parsing:
    ```bash
    # Extract from agent response
    DEBUG_REPORT_PATH=$(echo "$AGENT_OUTPUT" | grep "DEBUG_REPORT_CREATED:" | cut -d: -f2- | tr -d ' ')
    ROOT_CAUSE_SUMMARY=$(echo "$AGENT_OUTPUT" | sed -n '/Root Cause Summary/,/^$/p' | tail -n +2)

    # MANDATORY VERIFICATION
    if [[ ! -f "$DEBUG_REPORT_PATH" ]]; then
      error "CRITICAL: Debug report not created at $DEBUG_REPORT_PATH"
      # FALLBACK MECHANISM: Create minimal report
    fi
    ```

- [ ] Implement fix application loop
  - **EXECUTE NOW**: Extract proposed fix from debug report (read file for fix section)
  - **YOU MUST invoke** code-writer agent to apply the fix
  - **CRITICAL**: Use same behavioral injection pattern as implementation phase
  - **YOU WILL pass** debug report path for context
  - **YOU MUST re-run** test suite after fix applied
  - Example fix application:
    ```yaml
    Task {
      subagent_type: "general-purpose"
      description: "Apply fix from debug report"
      timeout: 300000
      prompt: |
        Apply the fix proposed in debug report:
        ${DEBUG_REPORT_PATH}

        Read the "Proposed Fix" section and implement the code changes.
        Use Edit tool to modify files as recommended.
        Run tests after changes to verify fix.
    }
    ```

- [ ] Implement iteration control and test re-run
  - **EXECUTE NOW**: After fix applied, re-run test suite
  - **YOU MUST parse** test results: tests_passing = true/false
  - **If tests pass**: Mark debug loop as successful, exit loop
  - **If tests fail and iteration < 3**:
    ```bash
    debug_iteration=$((debug_iteration + 1))
    # Generate new debug slug for iteration 2, 3
    DEBUG_SLUG="${DEBUG_SLUG}_iter${debug_iteration}"
    # Continue to next debug cycle
    ```
  - **If tests fail and iteration >= 3**: Escalate to user

- [ ] Add escalation handling for max iterations exceeded
  - **EXECUTE NOW**: Display all debug reports created (up to 3)
  - **YOU MUST show** last error message
  - **YOU WILL save** escalation checkpoint to `.claude/data/checkpoints/`
  - **YOU MUST provide** user with options:
    ```
    ⚠️ Implementation Blocked - Manual Intervention Required

    Debugging Attempts: 3 iterations
    Debug Reports Created:
      1. specs/027_authentication/debug/027_debug_oauth_token_validation.md
      2. specs/027_authentication/debug/027_debug_oauth_token_validation_iter2.md
      3. specs/027_authentication/debug/027_debug_oauth_token_validation_iter3.md

    Last Error: auth_spec.lua:42 - Expected 200, got 401

    Checkpoint Saved: .claude/data/checkpoints/080_phase1_debug_escalation.json

    Options:
      1. Review debug reports and provide guidance
      2. Adjust plan complexity and retry
      3. Continue to documentation with known test failures (not recommended)

    Workflow paused - awaiting user input.
    ```
  - Pause workflow execution, wait for user response

- [ ] Add validation after debug loop completion
  - **MANDATORY VERIFICATION**: Verify all debug reports created in `${ARTIFACT_DEBUG}` directory
  - **YOU MUST check** that debug reports follow naming convention: `${TOPIC_NUMBER}_debug_*.md`
  - **YOU WILL validate** debug reports are NOT in .gitignore (should be committed)
  - **YOU MUST update** workflow_state with debug iteration count and report paths
  - **FALLBACK MECHANISM**: If debug report in wrong location, move to `${ARTIFACT_DEBUG}`

- [ ] Update workflow state with debug results
  - `workflow_state.debug_iteration_count` - Number of debug cycles (0-3)
  - `workflow_state.debug_reports[]` - Array of debug report absolute paths
  - `workflow_state.debug_status` - "not_needed" | "resolved" | "escalated"
  - `workflow_state.tests_passing` - Final test status after debugging
  - **YOU MUST prepare** state for Documentation Phase consumption

**Testing**:

```bash
# Test Case 1: No test failures (debug loop skipped)
/orchestrate "Simple feature with passing tests"
# Verify: Debug loop not entered
# Verify: workflow_state.debug_status = "not_needed"

# Test Case 2: Test failure resolved in 1 iteration
# Modify orchestrate to simulate test failure
# Verify: debug-analyst invoked with artifact paths
# Verify: Debug report created at ${ARTIFACT_DEBUG}${TOPIC_NUMBER}_debug_*.md
# Verify: Fix applied, tests re-run and pass
# Verify: workflow_state.debug_iteration_count = 1
# Verify: workflow_state.debug_status = "resolved"

# Test Case 3: Test failures persist for 3 iterations (escalation)
# Simulate persistent test failure
# Verify: 3 debug reports created
# Verify: Escalation message displayed
# Verify: Checkpoint saved
# Verify: workflow_state.debug_status = "escalated"
# Verify: Workflow paused, awaiting user input

# Test Case 4: Debug report validation and fallback
# Simulate debug-analyst creating report in wrong location
# Verify: Validation detects misplaced report
# Verify: Report moved to ${ARTIFACT_DEBUG}
# Verify: Warning logged about misplacement
```

**Expected Outcomes**:
- Debug loop implemented in Implementation Phase of orchestrate.md
- debug-analyst agent invoked via Task tool with behavioral injection
- Artifact paths from Phase 0 location context injected correctly
- Debug reports created in `{topic_path}/debug/` with topic number prefix
- Fix application loop works: apply fix → re-run tests → evaluate
- Iteration control limits to 3 attempts before escalation
- Escalation displays all reports and provides user options
- Validation ensures debug reports in correct location
- Workflow state tracks debug results for Documentation Phase

---

### Stage 7: Update Documentation Phase with Artifact Path Injection

**Objective**: Replace manual summary path calculation in Documentation Phase with Phase 0 location context artifact paths, ensuring workflow summaries are saved to the correct topic-based location.

**Complexity**: Medium (4/10) - Simple replacement of path calculation logic

**Tasks**:

- [ ] Locate manual summary path calculation in orchestrate.md
  - **YOU MUST locate** Documentation Phase section (lines ~2560-2575)
  - **EXECUTE NOW**: Identify the manual path calculation block:
    ```bash
    PLAN_DIR=$(dirname "$IMPLEMENTATION_PLAN_PATH")
    PLAN_BASE=$(basename "$IMPLEMENTATION_PLAN_PATH" .md)
    PLAN_NUM=$(echo "$PLAN_BASE" | grep -oP '^\d+')
    SUMMARY_DIR="$(dirname "$PLAN_DIR")/summaries"
    mkdir -p "$SUMMARY_DIR"
    SUMMARY_PATH="$SUMMARY_DIR/${PLAN_NUM}_workflow_summary.md"
    ```
  - **CRITICAL**: This code is fragile (depends on plan path structure) and bypasses Phase 0

- [ ] Remove manual path calculation code
  - **EXECUTE NOW**: Delete the manual calculation block entirely
  - **YOU MUST remove** the `mkdir -p "$SUMMARY_DIR"` line (directory already created by Phase 0)
  - **MANDATORY VERIFICATION**: Ensure no references to PLAN_DIR, PLAN_BASE, PLAN_NUM for summary path

- [ ] Replace with Phase 0 location context path
  - **EXECUTE NOW**: Use location context artifact paths directly:
    ```bash
    # Summary path from Phase 0 location context (already absolute)
    SUMMARY_PATH="${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md"
    ```
  - **YOU MUST NOT use** dirname/basename manipulation
  - **YOU MUST NOT use** mkdir (Phase 0 already created directory)
  - **Result**: Simpler, more robust, consistent with other phases

- [ ] Update doc-writer agent prompt with artifact paths
  - **YOU MUST locate** doc-writer Task invocation (lines ~2488-2850)
  - **EXECUTE NOW**: Add ARTIFACT ORGANIZATION section to prompt:
    ```yaml
    doc-writer Prompt:
      Context:
       - Workflow description: ${WORKFLOW_DESCRIPTION}
       - Research reports: ${RESEARCH_REPORT_PATHS}
       - Implementation plan: ${IMPLEMENTATION_PLAN_PATH}
       - Implementation status: ${IMPLEMENTATION_STATUS}

      ARTIFACT ORGANIZATION (CRITICAL - From Phase 0 Location Context):
       - Summary path: ${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md
       - Use absolute path from location context
       - Topic number: ${TOPIC_NUMBER}
       - Topic name: ${TOPIC_NAME}
       - All artifact paths available for reference:
         - Reports: ${ARTIFACT_REPORTS}
         - Plans: ${ARTIFACT_PLANS}
         - Debug: ${ARTIFACT_DEBUG}
         - Summaries: ${ARTIFACT_SUMMARIES}
         - Outputs: ${ARTIFACT_OUTPUTS}
       - DO NOT calculate summary path manually
       - DO NOT use relative paths

      Documentation Requirements:
       - Create comprehensive workflow summary
       - Include cross-references to all artifacts
       - Use topic number in summary filename
       - Save to specified summary path
    ```

- [ ] Inject location context variables into doc-writer prompt
  - **YOU MUST pass** all artifact paths from location_context
  - **YOU WILL pass** topic number, topic name, topic path
  - **YOU MUST ensure** doc-writer has access to all Phase 0 context
  - **CRITICAL**: Variables to inject:
    - `${ARTIFACT_SUMMARIES}` - Summary directory path
    - `${ARTIFACT_REPORTS}` - Reports directory (for cross-references)
    - `${ARTIFACT_PLANS}` - Plans directory (for cross-references)
    - `${ARTIFACT_DEBUG}` - Debug directory (for cross-references)
    - `${TOPIC_NUMBER}` - Topic number for filename prefix
    - `${TOPIC_NAME}` - Topic name for summary metadata
    - `${TOPIC_PATH}` - Full topic directory path

- [ ] Add validation after doc-writer completion
  - **MANDATORY VERIFICATION**: Verify summary created at expected location:
    ```bash
    EXPECTED_SUMMARY_PATH="${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md"

    if [[ ! -f "$EXPECTED_SUMMARY_PATH" ]]; then
      error "CRITICAL: Workflow summary not created at expected location: $EXPECTED_SUMMARY_PATH"

      # FALLBACK MECHANISM: Search for summary file in common locations
      FOUND_SUMMARY=$(find "${TOPIC_PATH}" -name "*workflow_summary.md" -o -name "*summary.md" | head -n 1)

      if [[ -n "$FOUND_SUMMARY" ]]; then
        warn "Found summary in wrong location: $FOUND_SUMMARY"
        warn "Moving to correct location: $EXPECTED_SUMMARY_PATH"
        mv "$FOUND_SUMMARY" "$EXPECTED_SUMMARY_PATH"
      else
        error "CRITICAL: Workflow summary not found anywhere in topic directory"
        # Manual intervention required
      fi
    else
      log "✓ VERIFIED: Workflow summary validated at: $EXPECTED_SUMMARY_PATH"
    fi
    ```

- [ ] Update summary metadata to include location context
  - **YOU MUST ensure** doc-writer includes topic information in summary metadata:
    ```markdown
    # Workflow Summary: [Feature Name]

    ## Metadata
    - **Date**: 2025-10-21
    - **Topic Number**: 027
    - **Topic Name**: authentication
    - **Topic Path**: /home/user/.config/specs/027_authentication/
    - **Workflow Type**: feature
    - **Completion Status**: success

    ## Artifact Organization
    All artifacts for this workflow are organized in:
    - **Reports**: specs/027_authentication/reports/
    - **Plans**: specs/027_authentication/plans/
    - **Debug**: specs/027_authentication/debug/
    - **Summaries**: specs/027_authentication/summaries/
    ```
  - **YOU WILL inject** topic metadata into doc-writer prompt
  - **YOU MUST validate** summary includes topic information

- [ ] Remove dependency on plan path structure
  - **Before**: Summary path derived from plan path (fragile)
  - **After**: Summary path from Phase 0 location context (robust)
  - **Benefit 1**: Plans can be renamed/moved without breaking summary path
  - **Benefit 2**: Consistent with all other phases (Research, Planning, Debug)

**Testing**:

```bash
# Test Case 1: Documentation phase with Phase 0 location context
/orchestrate "Test documentation with artifact organization"
# Verify: No manual path calculation in Documentation Phase
# Verify: Summary created at ${ARTIFACT_SUMMARIES}${TOPIC_NUMBER}_workflow_summary.md
# Verify: Summary metadata includes topic number and paths
# Verify: No errors about missing directories

# Test Case 2: Summary path validation and fallback
# Simulate doc-writer creating summary in wrong location
echo "test" > /tmp/wrong_summary.md
# Simulate agent returning wrong path
# Verify: Validation detects wrong location
# Verify: Summary moved to correct location
# Verify: Warning logged

# Test Case 3: Cross-references in summary
# Complete full workflow with all phases
# Verify: Summary includes references to:
#   - Research reports (from ${ARTIFACT_REPORTS})
#   - Implementation plan (from ${ARTIFACT_PLANS})
#   - Debug reports if any (from ${ARTIFACT_DEBUG})
# Verify: All references use relative paths from summary location
```

**Expected Outcomes**:
- Manual summary path calculation removed from orchestrate.md
- Summary path derived from Phase 0 location context (${ARTIFACT_SUMMARIES})
- doc-writer prompt includes artifact organization section with all paths
- Location context variables injected into doc-writer prompt
- Validation ensures summary created in correct location with fallback
- Summary metadata includes topic information from location context
- Documentation Phase consistent with Research, Planning, Debug phases
- No dependency on plan file path structure

---

## Phase Completion Checklist

- [ ] **Stage 1 Complete**: location-specialist agent created and tested
 - Agent file exists at `.claude/agents/location-specialist.md`
 - Directory analysis logic correctly identifies affected components
 - Topic numbering handles all edge cases
 - Directory creation succeeds with error handling
 - Location context object returns absolute paths

- [ ] **Stage 2 Complete**: location-specialist integrated into orchestrate.md
 - Phase 0 added to orchestrate.md workflow
 - location-specialist invoked using Task tool (not SlashCommand)
 - Location context extracted and stored in workflow state
 - Validation confirms directory structure created
 - User sees Phase 0 summary

- [ ] **Stage 3 Complete**: Research phase receives artifact path injection
 - Research prompts include artifact_paths.reports
 - All research reports created in correct location
 - Reports use topic number prefix
 - Artifact validation detects and corrects misplaced files
 - Workflow state contains correct paths

- [ ] **Stage 4 Complete**: Planning and Debug phases receive artifact path injection
 - Planning prompts include artifact_paths.plans
 - Plans created in correct location with topic number metadata
 - Debug prompts include artifact_paths.debug
 - Debug reports created in committed debug/ directory
 - Path validation corrects misplaced files

- [ ] **Stage 5 Complete**: Artifact validation and fallback [SKIPPED]
 - Stage skipped - inline validation in Stages 2-4 is sufficient
 - No separate validation utility needed

- [x] **Stage 6 Complete**: Debug loop with artifact path injection implemented
 - Debug loop added to Implementation Phase in orchestrate.md
 - debug-analyst Task invocation created with behavioral injection
 - Artifact paths from Phase 0 injected (ARTIFACT_DEBUG, ARTIFACT_OUTPUTS, etc.)
 - Fix application loop implemented (debug → fix → test → evaluate)
 - Iteration control limits to 3 attempts before escalation
 - Escalation handling displays all reports and pauses workflow
 - Validation ensures debug reports in correct topic-based location
 - Workflow state tracks debug results

- [x] **Stage 7 Complete**: Documentation phase artifact path injection
 - Manual summary path calculation removed from orchestrate.md
 - Summary path uses Phase 0 location context (ARTIFACT_SUMMARIES)
 - doc-writer prompt includes artifact organization section
 - Location context variables injected (topic number, paths, etc.)
 - Validation with fallback for misplaced summaries
 - Summary metadata includes topic information
 - Documentation Phase consistent with other phases

- [x] **All phase tasks completed and marked [x]**

- [ ] **All tests passing**:
 ```bash
 # Test Phase 1 end-to-end
 /orchestrate "Test artifact organization with simple workflow"

 # Verify all artifacts in correct locations
 # Verify location-specialist creates topic directories
 # Verify all phases inject artifact paths correctly
 # Verify validation detects and corrects misplaced files
 # Verify artifact summary displayed at end
 ```

- [ ] **Update Phase 1 status in parent plan**:
 - Mark Phase 1 as complete in `080_orchestrate_enhancement.md`
 - Update phase summary with completion notes
 - Propagate completion to Level 0 plan

- [ ] **Create git commit**:
 ```bash
 git add .claude/agents/location-specialist.md
 git add .claude/commands/orchestrate.md
 git commit -m "feat(080): complete Phase 1 - Foundation: Location Specialist and Artifact Organization

 - Created location-specialist agent for project location analysis
 - Added Phase 0 to orchestrate.md for topic directory creation
 - Injected artifact paths into Research, Planning, and Debug phases
 - Implemented artifact validation and fallback for misplaced files
 - All artifacts now organized in topic-based structure: specs/NNN_topic/

 Tests: All artifact organization tests passing
 Coverage: location-specialist, Phase 0 integration, artifact validation"
 ```

- [ ] **Create checkpoint**:
 ```bash
 # Save progress to checkpoint
 .claude/lib/checkpoint-utils.sh create \
  --plan "080_orchestrate_enhancement" \
  --phase 1 \
  --status "complete" \
  --message "Phase 1 complete: Artifact organization foundation established"
 ```

- [ ] **Invoke spec-updater** to update cross-references:
 - Update parent plan with Phase 1 completion status
 - Validate hierarchical structure integrity
 - Update artifact lifecycle metadata

---

## Testing Summary

### Unit Tests
- location-specialist agent directory analysis
- Topic number determination with edge cases
- Artifact path injection into subagent prompts
- Artifact validation utility function
- Fallback file movement logic

### Integration Tests
- End-to-end /orchestrate with artifact organization
- Phase 0 → Research → Planning → Debug artifact flow
- Validation across all phases
- Workflow state artifact path storage

### Validation Tests
- All artifacts in correct topic-based structure
- Topic numbers consistent across all artifacts
- Absolute paths used throughout
- Misplaced artifacts detected and corrected
- Artifact summary displayed accurately

---

## Dependencies

### Required Infrastructure
- `.claude/agents/` directory for location-specialist agent
- `.claude/commands/orchestrate.md` for Phase 0 integration
- Existing subagent templates (research-specialist, plan-architect, debug-specialist)
- Task tool for subagent invocation (not SlashCommand)

### External Dependencies
- Phase 0 (Remove command-to-command invocations) MUST be complete
 - Without Phase 0, [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) will fail
 - SlashCommand invocations prevent artifact path context from reaching subagents
- Project must have specs/ directory or permission to create it
- Bash environment with mkdir, mv, basename utilities

### Blocks
- Phase 2: Research Synthesis (needs artifact organization working)
- Phase 3: Complexity Evaluation (needs plans in correct location)
- Phase 4: Plan Expansion (needs artifact paths for hierarchical structure)
- Phase 5: Wave-Based Implementation (needs artifact paths for debug/output)
- Phase 6: Comprehensive Testing (needs artifact paths for test results)
- Phase 7: Progress Tracking (needs artifact paths for summaries)

---

## Notes

### Critical Success Factors

1. **Phase 0 Dependency**: This phase CANNOT work without Phase 0 completion. Command-to-command invocations via SlashCommand prevent [Behavioral Injection Pattern](../../../docs/concepts/patterns/behavioral-injection.md) from working. Artifact path context will not reach subagents if orchestrate.md continues to call /plan, /implement, etc. via SlashCommand.

2. **Absolute Paths**: All artifact paths MUST be absolute. Relative paths break when subagents have different working directories. location-specialist must return absolute paths in location_context.

3. **Validation is Mandatory**: Artifact validation after each phase is not optional. Without it, misplaced artifacts accumulate and break downstream phases (e.g., research-synthesizer cannot find reports, implementer cannot find plan).

4. **Debug Directory is Committed**: Unlike other artifact directories (reports/, plans/, summaries/), the debug/ directory is committed to version control. This is intentional for issue tracking. Ensure gitignore rules don't accidentally exclude it.

### Common Pitfalls

1. **Relative Paths**: Using relative paths like `./specs/027_auth/` instead of `/absolute/path/to/specs/027_auth/` causes failures when subagents run in different directories.

2. **Missing Validation**: Skipping artifact validation allows misplaced files to accumulate. Always validate after each phase.

3. **Topic Number Collisions**: If two /orchestrate workflows run simultaneously, they might both create topic 027. Topic numbering logic MUST handle retries (028, 029, etc.) until unique number found.

4. **Permission Errors**: If specs/ directory doesn't exist and user lacks write permissions, directory creation fails. Gracefully handle with clear error message.

### Performance Considerations

- Directory creation is fast (<100ms), minimal overhead
- Artifact validation adds ~10-50ms per artifact, acceptable
- Location context object is small (<500 bytes), negligible memory impact
- No impact on context window (metadata-only passing maintained)

### Future Enhancements

1. **Multi-Project Support**: Currently assumes single project. Future extension WILL handle monorepos with multiple spec/ directories.

2. **Custom Directory Structures**: Allow projects to override default directory structure (reports/, plans/, etc.) via CLAUDE.md configuration.

3. **Artifact Cleanup**: Add utility to clean up old gitignored artifacts (reports/, plans/) after workflow completion, keeping only debug/ and summaries/.

4. **Artifact Linking**: Automatically create cross-reference links between related artifacts (e.g., plan links to research reports, summary links to plan and reports).
