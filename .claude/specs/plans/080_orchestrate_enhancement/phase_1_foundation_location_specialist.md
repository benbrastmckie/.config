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

### Stage 5: Implement Artifact Validation and Fallback

**Objective**: Add comprehensive artifact validation after each phase completion to ensure all artifacts are in correct locations, with automatic fallback to move misplaced files.

**Complexity**: Medium (5/10)

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

- [ ] **Stage 5 Complete**: Artifact validation and fallback implemented
 - Validation utility function works for all artifact types
 - Validation runs after every phase
 - Artifact organization summary displayed
 - Metrics track placement success rate
 - Workflow completion requires artifact validation

- [ ] **All phase tasks completed and marked [x]**

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
