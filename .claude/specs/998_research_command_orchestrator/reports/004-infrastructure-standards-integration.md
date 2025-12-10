# Infrastructure Integration and Standards Compliance

## Executive Summary

The /research command optimization must integrate with five critical infrastructure systems: state persistence, error logging, command authoring patterns, hierarchical agent architecture, and code quality enforcement. This research identifies mandatory patterns, compliance requirements, and integration checkpoints to ensure the optimized research-coordinator pattern maintains full standards compliance while achieving 95% context reduction and 40-60% time savings.

## Findings

### 1. State Persistence Integration Requirements

**Library**: `.claude/lib/core/state-persistence.sh` (v1.6.0)

**Mandatory Patterns**:

1. **Three-Tier Library Sourcing** (Command Authoring Standard):
   - Tier 1 (Critical): state-persistence.sh, workflow-state-machine.sh, error-handling.sh, validation-utils.sh
   - MUST use fail-fast handlers: `source "${LIB}" 2>/dev/null || { echo "ERROR: Failed to source" >&2; exit 1; }`
   - Re-source in EVERY bash block (subprocess isolation)

2. **Workflow State Initialization** (Block 1 only):
   ```bash
   STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")
   trap "rm -f '$STATE_FILE'" EXIT
   ```

3. **State Loading** (Block 2+):
   ```bash
   load_workflow_state "$WORKFLOW_ID" false  # fail-fast mode
   validate_state_restoration "COMMAND_NAME" "WORKFLOW_ID" "REPORT_PATHS_LIST"
   ```

4. **State Persistence for Multi-Report Context**:
   - Use space-separated strings for array-like data (NOT JSON arrays)
   - `append_workflow_state "REPORT_PATHS_LIST" "/path/1 /path/2 /path/3"`
   - For JSON metadata: Use `_JSON` suffix or allowlisted keys

5. **CLAUDE_PROJECT_DIR Path Pattern**:
   - CORRECT: `STATE_FILE="${CLAUDE_PROJECT_DIR}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"`
   - WRONG: `STATE_FILE="${HOME}/.claude/tmp/workflow_${WORKFLOW_ID}.sh"` (PATH MISMATCH)

**Critical State Variables for Research Coordinator**:
- `TOPICS_LIST` - Space-separated research topics
- `REPORT_PATHS_LIST` - Space-separated absolute report paths (hard barrier contract)
- `RESEARCH_COMPLEXITY` - Complexity level (triggers coordinator vs specialist)
- `FEATURE_DESCRIPTION` - User input for topic naming agent
- `TOPIC_DIR` - Topic directory path

**Performance Considerations**:
- CLAUDE_PROJECT_DIR detection: 15ms (cached in state file vs 50ms git rev-parse)
- State file append: <1ms per variable
- State file load: 2-5ms (sourcing bash exports)

### 2. Error Logging Standards Integration

**Library**: `.claude/lib/core/error-handling.sh`

**Mandatory Patterns**:

1. **Dual Trap Setup** (100% error coverage):
   ```bash
   # EARLY TRAP: Immediately after sourcing error-handling.sh
   setup_bash_error_trap "/research" "research_early_$(date +%s)" "early_init"
   _flush_early_errors

   # Validate trap active
   if ! trap -p ERR | grep -q "_log_bash_error"; then
     echo "ERROR: ERR trap not active" >&2
     exit 1
   fi

   # LATE TRAP: After WORKFLOW_ID available
   setup_bash_error_trap "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS"
   ```

2. **Error Type Selection Guide**:
   - `validation_error` - Invalid user input (missing --file, invalid complexity)
   - `state_error` - State file missing, variable restoration failed
   - `agent_error` - research-coordinator or research-specialist invocation failed
   - `parse_error` - Topic decomposition JSON parsing failed
   - `file_error` - Report file validation failed (hard barrier)
   - `execution_error` - General execution failures

3. **Agent Error Parsing and Logging**:
   ```bash
   error_json=$(parse_subagent_error "$coordinator_output")
   if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
     log_command_error \
       "$COMMAND_NAME" \
       "$WORKFLOW_ID" \
       "$USER_ARGS" \
       "$(echo "$error_json" | jq -r '.error_type')" \
       "research-coordinator failed: $(echo "$error_json" | jq -r '.message')" \
       "subagent_research-coordinator" \
       "$(echo "$error_json" | jq -c '.context')"
   fi
   ```

4. **State Persistence Error Suppression Prevention**:
   - NEVER: `append_workflow_state "KEY" "value" 2>/dev/null`
   - ALWAYS: Explicit error handling with log_command_error before exit

5. **Error Context Persistence Across Blocks**:
   - Block 1: Export COMMAND_NAME, USER_ARGS immediately after ensure_error_log_exists
   - Block 2+: Variables auto-restored by load_workflow_state
   - Enables accurate error logging in any bash block

**Environment-Based Error Routing**:
- Production log: `.claude/data/logs/errors.jsonl`
- Test log: `.claude/tests/logs/test-errors.jsonl`
- Automatic routing via `CLAUDE_TEST_MODE=1` or path detection

**Coverage Target**: 80%+ of error exit points MUST call log_command_error before exit 1

### 3. Command Authoring Pattern Compliance

**Source**: `.claude/docs/reference/standards/command-authoring.md`

**Critical Compliance Points**:

1. **Execution Directive Requirements**:
   - All bash blocks MUST have imperative directive: `**EXECUTE NOW**: ...`
   - Task invocations MUST have: `**EXECUTE NOW**: USE the Task tool to invoke...`
   - NO code block wrappers around Task invocations

2. **Task Invocation Pattern** (research-coordinator):
   ```markdown
   **EXECUTE NOW**: USE the Task tool to invoke research-coordinator agent.

   Task {
     subagent_type: "general-purpose"
     model: "sonnet"
     description: "Coordinate parallel research for ${TOPICS_COUNT} topics"
     prompt: "
       Read and follow ALL behavioral guidelines from:
       ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

       **Topics**: ${TOPICS_LIST}
       **Report Paths**: ${REPORT_PATHS_LIST}
       **Hard Barrier**: All reports MUST exist at specified paths

       Return: COORDINATION_COMPLETE: ${REPORTS_COUNT} reports created
     "
   }
   ```

3. **Subprocess Isolation Requirements**:
   - `set +H` at start of EVERY bash block (disable history expansion)
   - Re-source libraries in EVERY block (functions don't persist)
   - Explicit return code checks for critical functions

4. **Argument Capture Pattern** (2-Block Standard):
   - Block 1: Mechanical capture with `YOUR_DESCRIPTION_HERE` substitution
   - Block 2: Validation and flag parsing (--complexity, --file)

5. **Path Initialization Pattern** (Topic Naming Agent):
   - Commands create topic directories via `create_topic_structure()`
   - Agents create artifact subdirectories via `ensure_artifact_directory()`
   - NEVER: Eager `mkdir -p $RESEARCH_DIR` in commands

6. **Output Suppression Requirements**:
   - Library sourcing: `source "${LIB}" 2>/dev/null || { echo "ERROR" >&2; exit 1; }`
   - Directory operations: `mkdir -p "$DIR" 2>/dev/null || true`
   - Single summary line per block (not multiple progress messages)

7. **Block Consolidation Strategy**:
   - Target: 2-3 bash blocks per command (Setup/Execute/Cleanup)
   - Research command: Block 1a-f (Setup), Block 2 (Coordinator), Block 3 (Validation)

8. **Plan Metadata Standard Integration**:
   ```bash
   source "${CLAUDE_LIB}/plan/standards-extraction.sh" 2>/dev/null || {
     log_command_error "dependency_error" "Cannot load standards-extraction"
   }
   FORMATTED_STANDARDS=$(format_standards_for_prompt "$STANDARDS_FILE")
   ```

9. **Prohibited Patterns**:
   - NEVER: `if ! some_command; then` (use exit code capture)
   - NEVER: Naked Task blocks without `**EXECUTE NOW**` directive
   - NEVER: JSON arrays in append_workflow_state (use space-separated strings)

### 4. Hierarchical Agent Architecture Integration

**Source**: `.claude/docs/concepts/hierarchical-agents-overview.md`

**Architecture Patterns**:

1. **Three-Level Hierarchy**:
   ```
   /research Command (Orchestrator)
       |
       +-- research-coordinator (Supervisor)
               |
               +-- research-specialist (Worker 1)
               +-- research-specialist (Worker 2)
               +-- research-specialist (Worker 3)
   ```

2. **Behavioral Injection Pattern**:
   - Single source of truth: `.claude/agents/research-coordinator.md`
   - Runtime injection via Task tool prompt field
   - NO hardcoded behavior in commands

3. **Metadata-Only Context Passing**:
   - Workers produce full reports (2,500 tokens each)
   - Supervisor extracts metadata (110 tokens per report)
   - Orchestrator receives aggregated metadata (440 tokens for 4 reports)
   - Context reduction: 95%+ (10,000 → 440 tokens)

4. **Hard Barrier Subagent Delegation**:
   - Pre-calculate report paths in command (Block 1d)
   - Pass paths to coordinator as contract
   - Coordinator MUST invoke specialists (not optional)
   - Multi-report validation loop enforces completion (Block 1f)

5. **Supervisor-Based Parallelization**:
   - Supervisor coordinates parallel worker invocations
   - 40-60% time savings vs sequential execution
   - Workers write to pre-calculated paths (hard barrier)

6. **Agent Communication Signals**:
   - Success: `COORDINATION_COMPLETE: 3 reports created`
   - Error: `TASK_ERROR: {error_type} - {message}` with ERROR_CONTEXT JSON

7. **Model Tier Selection**:
   - Orchestrator: N/A (command, not agent)
   - Supervisor (research-coordinator): `model: "sonnet"` for coordination logic
   - Workers (research-specialist): `model: "opus"` for research quality (via agent frontmatter)

**Integration Checkpoints**:

1. Topic Decomposition (Block 1d):
   - Heuristic-based or topic-detection-agent
   - Persist TOPICS_LIST and REPORT_PATHS_LIST to state
   - Fallback to single-topic mode on failure

2. Coordinator Invocation (Block 1e):
   - Task invocation with pre-calculated paths
   - Hard barrier contract enforcement
   - Metadata-only return expected

3. Multi-Report Validation (Block 1f):
   - Iterate REPORT_PATHS_LIST with fail-fast policy
   - Extract metadata (title, summary, findings count)
   - Aggregate for plan-architect context

4. Graceful Degradation:
   - Topic decomposition failure → single-topic mode
   - Coordinator failure → log error, suggest /errors query
   - Partial report completion → fail (hard barrier enforcement)

### 5. Code Quality Enforcement Integration

**Automated Validators**:

1. **Library Sourcing** (`check-library-sourcing.sh`):
   - Validates three-tier sourcing pattern
   - Enforces fail-fast handlers for Tier 1 libraries
   - Severity: ERROR (blocks commits)

2. **Error Suppression** (`lint_error_suppression.sh`):
   - Detects state persistence error suppression
   - Validates deprecated state paths
   - Severity: ERROR (blocks commits)

3. **Bash Conditionals** (`lint_bash_conditionals.sh`):
   - Detects `if !` and `elif !` anti-patterns
   - Enforces exit code capture pattern
   - Severity: ERROR (blocks commits)

4. **Plan Metadata** (`validate-plan-metadata.sh`):
   - Validates required metadata fields in plans
   - Checks format compliance (date, status, hours)
   - Severity: WARNING (informational only)

5. **Non-Interactive Testing** (`validate-non-interactive-tests.sh`):
   - Detects interactive anti-patterns in test phases
   - Validates automation metadata fields
   - Severity: ERROR (blocks workflow)

**Pre-Commit Hook Integration**:
- Runs on all staged `.claude/` files
- ERROR-level violations block commits
- Bypass: `git commit --no-verify` (document justification)

**Validation Commands**:
```bash
# Run all validators
bash .claude/scripts/validate-all-standards.sh --all

# Run specific categories
bash .claude/scripts/validate-all-standards.sh --sourcing
bash .claude/scripts/validate-all-standards.sh --suppression
bash .claude/scripts/validate-all-standards.sh --conditionals
```

**Research Command Validation Checklist**:
- [ ] Three-tier sourcing in all bash blocks
- [ ] Fail-fast handlers for state-persistence.sh, workflow-state-machine.sh, error-handling.sh
- [ ] No `if !` or `elif !` patterns (use exit code capture)
- [ ] No error suppression on append_workflow_state calls
- [ ] Execution directives on all bash blocks and Task invocations
- [ ] 80%+ error logging coverage (log_command_error before exits)
- [ ] State file path uses CLAUDE_PROJECT_DIR (not HOME)

### 6. Output Formatting and Console Standards

**Library Sourcing Suppression**:
- ALWAYS: `2>/dev/null` with fail-fast handlers
- Prevents verbose function definition output

**Single Summary Line per Block**:
- Block 1: "Research setup complete: ${WORKFLOW_ID}"
- Block 2: "Coordination complete: ${REPORTS_COUNT} reports created"
- Block 3: "Validation complete: ${REPORTS_COUNT} reports verified"

**Console Summary Format** (Final output):
```
## Summary
Multi-topic research coordination completed with 95% context reduction.

## Topics Researched
1. Topic 1 (findings: 12)
2. Topic 2 (findings: 8)
3. Topic 3 (findings: 15)

## Artifacts Created
- 3 research reports in ${TOPIC_DIR}/reports/
- Reports: 001_topic1.md, 002_topic2.md, 003_topic3.md

## Next Steps
- Review reports: ls -la ${TOPIC_DIR}/reports/
- Create plan: /create-plan --file ${REPORT_PATHS[0]}
- Query errors: /errors --workflow-id ${WORKFLOW_ID}
```

**Comment Standards** (WHAT not WHY):
- Correct: `# Load state management functions`
- Incorrect: `# We source here because subprocess isolation requires re-sourcing`

### 7. Directory Creation and Lazy Loading

**Command Responsibilities**:
- Create topic root directory: `TOPIC_DIR=$(create_topic_structure "$DESCRIPTION")`
- NEVER create artifact subdirectories: NO `mkdir -p $RESEARCH_DIR`

**Agent Responsibilities**:
- Create artifact subdirectories via `ensure_artifact_directory()`
- Guarantees parent directory exists before Write tool invocation

**Anti-Pattern Detection**:
```bash
# WRONG: Eager creation in command
mkdir -p "${TOPIC_DIR}/reports"
mkdir -p "${TOPIC_DIR}/plans"

# CORRECT: Lazy creation in agent
ensure_artifact_directory "$REPORT_PATH" || exit 1
# Write tool creates file (directory guaranteed to exist)
```

**Benefits**:
- No empty directories when workflows fail
- Consistent with lazy creation standard
- Simpler command code (agents control lifecycle)

## Recommendations

### 1. State Persistence Integration

**Block 1a-c: Setup and State Initialization**:
1. Source libraries with three-tier pattern (fail-fast for Tier 1)
2. Initialize error log with `ensure_error_log_exists`
3. Set dual trap setup (early + late)
4. Initialize workflow state: `STATE_FILE=$(init_workflow_state "$WORKFLOW_ID")`
5. Persist error context: Export COMMAND_NAME, USER_ARGS

**Block 1d: Topic Decomposition**:
1. Source topic-decomposition.sh library
2. Decompose user description into topics array
3. Pre-calculate report paths (hard barrier contract)
4. Persist to state:
   - `append_workflow_state "TOPICS_LIST" "${TOPICS[*]}"` (space-separated)
   - `append_workflow_state "REPORT_PATHS_LIST" "${REPORT_PATHS[*]}"`

**Block 1e: Coordinator Invocation**:
1. Load workflow state (fail-fast mode)
2. Validate state restoration: TOPICS_LIST, REPORT_PATHS_LIST
3. Invoke research-coordinator with pre-calculated paths

**Block 1f: Multi-Report Validation**:
1. Load workflow state
2. Iterate REPORT_PATHS_LIST with file existence checks
3. Extract metadata from each report
4. Aggregate metadata for plan-architect context

### 2. Error Logging Integration

**Mandatory Error Logging Points**:

1. **Argument Validation**:
   ```bash
   if [ -z "$FEATURE_DESCRIPTION" ]; then
     log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
       "validation_error" "Feature description required" "argument_validation" \
       "$(jq -n --arg provided "$*" '{provided_args: $provided}')"
     exit 1
   fi
   ```

2. **State File Validation**:
   ```bash
   if ! validate_state_file "$STATE_FILE"; then
     log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
       "state_error" "State file validation failed" "load_workflow_state" \
       "$(jq -n --arg path "$STATE_FILE" '{state_file: $path}')"
     exit 1
   fi
   ```

3. **Agent Invocation Failures**:
   ```bash
   error_json=$(parse_subagent_error "$coordinator_output")
   if [ "$(echo "$error_json" | jq -r '.found')" = "true" ]; then
     log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
       "$(echo "$error_json" | jq -r '.error_type')" \
       "research-coordinator failed: $(echo "$error_json" | jq -r '.message')" \
       "subagent_research-coordinator" \
       "$(echo "$error_json" | jq -c '.context')"
     exit 1
   fi
   ```

4. **Report File Validation** (Hard Barrier):
   ```bash
   if [ ! -f "$REPORT_PATH" ]; then
     log_command_error "$COMMAND_NAME" "$WORKFLOW_ID" "$USER_ARGS" \
       "file_error" "Report file not found: $REPORT_PATH" "multi_report_validation" \
       "$(jq -n --arg path "$REPORT_PATH" --arg topic "$TOPIC" \
         '{expected_path: $path, topic: $topic, barrier: "hard"}')"
     exit 1
   fi
   ```

**Error Recovery Workflow**:
1. User encounters error during /research execution
2. Query recent errors: `/errors --command /research --limit 5`
3. Analyze patterns: `/repair --command /research --complexity 2`
4. Implement fix: `/implement [repair-plan]`
5. Validate fix: `/test [repair-plan]`

### 3. Command Authoring Compliance

**Template Structure** (2-3 Block Pattern):

**Block 1a-c: Setup**:
- Argument capture with YOUR_DESCRIPTION_HERE substitution
- Validation and flag parsing (--complexity, --file)
- Library sourcing with three-tier pattern
- State initialization and error trap setup
- Topic directory allocation via create_topic_structure()

**Block 1d-f: Research Coordination**:
- Topic decomposition (heuristic or automated)
- research-coordinator invocation with hard barrier contract
- Multi-report validation loop

**Block 2: Completion**:
- Metadata aggregation for downstream commands
- Console summary output
- State cleanup (trap handles file deletion)

**Execution Directive Template**:
```markdown
**EXECUTE NOW**: USE the Task tool to invoke research-coordinator agent.

Task {
  subagent_type: "general-purpose"
  model: "sonnet"
  description: "Coordinate parallel research for ${TOPICS_COUNT} topics with mandatory file creation"
  prompt: "
    Read and follow ALL behavioral guidelines from:
    ${CLAUDE_PROJECT_DIR}/.claude/agents/research-coordinator.md

    **Workflow-Specific Context**:
    - Topics: ${TOPICS_LIST}
    - Report Paths: ${REPORT_PATHS_LIST}
    - Output Directory: ${RESEARCH_DIR}

    Execute coordination per behavioral guidelines.
    Return: COORDINATION_COMPLETE: ${REPORTS_COUNT} reports created
  "
}
```

**Prohibited Pattern Avoidance**:
- NEVER: `if ! create_topic_structure; then` → Use exit code capture
- NEVER: Naked Task blocks without `**EXECUTE NOW**`
- NEVER: JSON arrays in append_workflow_state → Use space-separated strings

### 4. Hierarchical Agent Architecture Integration

**Coordinator Agent Enhancements** (research-coordinator.md):

1. **Frontmatter Model Specification**:
   ```yaml
   ---
   model: sonnet
   description: Coordinates parallel research specialists with metadata aggregation
   ---
   ```

2. **STEP 3: Parallel Worker Invocation** (Hard Barrier Pattern):
   ```markdown
   **EXECUTE NOW**: USE the Task tool to invoke research-specialist for topic 1.

   Task {
     subagent_type: "general-purpose"
     model: "opus"
     description: "Research topic 1 with mandatory file creation"
     prompt: "
       Read and follow ALL behavioral guidelines from:
       ${CLAUDE_PROJECT_DIR}/.claude/agents/research-specialist.md

       **CRITICAL - Hard Barrier Pattern**:
       REPORT_PATH=${REPORT_PATHS[0]}  (exact absolute path from array)

       **Research Topic**: ${TOPICS[0]}  (exact topic string from array)

       Execute research per behavioral guidelines.
       Return: REPORT_CREATED: ${REPORT_PATHS[0]}
     "
   }
   ```

3. **STEP 4: Metadata Extraction and Aggregation**:
   - Extract from each report: title, summary (50 words), findings count
   - Aggregate into metadata JSON
   - Return metadata-only to orchestrator (95% context reduction)

**Specialist Agent Requirements** (research-specialist.md):

1. **Hard Barrier Compliance**:
   - MUST create report at REPORT_PATH (not optional)
   - Validate report written before returning
   - Return signal: `REPORT_CREATED: ${REPORT_PATH}`

2. **Error Signaling**:
   - On failure: `TASK_ERROR: {error_type} - {message}`
   - Include ERROR_CONTEXT JSON with details

3. **Output Structure** (Consistent for Metadata Extraction):
   - `## Executive Summary` (2-3 sentences)
   - `## Findings` (bullet points with file references)
   - `## Recommendations` (actionable next steps)

### 5. Code Quality Enforcement Compliance

**Pre-Implementation Validation**:
1. Lint library sourcing: `bash .claude/scripts/lint/check-library-sourcing.sh .claude/commands/research.md`
2. Lint error suppression: `bash .claude/tests/utilities/lint_error_suppression.sh`
3. Lint conditionals: `bash .claude/tests/utilities/lint_bash_conditionals.sh`

**Post-Implementation Validation**:
1. Run all validators: `bash .claude/scripts/validate-all-standards.sh --all`
2. Test error logging coverage (manual review of log_command_error calls)
3. Verify state persistence integration (test multi-block state restoration)

**Pre-Commit Hook Enforcement**:
- ERROR-level violations will block commits
- WARNING-level violations are informational only
- Document bypass justification if using `--no-verify`

### 6. Testing and Validation Strategy

**Unit Tests** (`.claude/tests/test_research_coordinator.sh`):
1. Topic decomposition logic (heuristic and agent-based)
2. Report path pre-calculation
3. State persistence and restoration
4. Multi-report validation loop
5. Metadata extraction and aggregation

**Integration Tests** (`.claude/tests/integration/test_research_e2e.sh`):
1. End-to-end workflow with 3-topic research
2. Coordinator invocation and specialist delegation
3. Hard barrier enforcement (missing report detection)
4. Error logging coverage validation
5. Console summary format validation

**Performance Tests** (`.claude/tests/performance/test_research_performance.sh`):
1. Context reduction measurement (baseline vs coordinator)
2. Parallel execution time savings (sequential vs parallel)
3. State persistence overhead (<15ms target)

**Non-Interactive Test Compliance**:
- All tests MUST be fully automated (no manual verification)
- Use `CLAUDE_TEST_MODE=1` for test error log isolation
- Clear test logs between runs: `rm -f .claude/tests/logs/test-errors.jsonl`

### 7. Documentation Requirements

**Command Guide** (`.claude/docs/guides/commands/research-command-guide.md`):
- Architecture overview (3-level hierarchy)
- Usage examples (single-topic vs multi-topic)
- Complexity thresholds (when to use coordinator)
- Troubleshooting guide (common issues and solutions)
- Performance characteristics (context reduction, time savings)

**Standards Integration** (CLAUDE.md updates):
- Update `research_invocation_standards` section with coordinator pattern
- Add research command to `error_logging` section "Used by" list
- Document research-coordinator in `hierarchical_agent_architecture` section

**Agent Documentation** (`.claude/agents/research-coordinator.md`):
- Behavioral guidelines (STEP-by-STEP execution)
- Hard barrier pattern enforcement
- Metadata extraction standards
- Error signaling protocol

## References

### Documentation Files Examined

1. `/home/benjamin/.config/.claude/docs/reference/standards/command-authoring.md` (2,078 lines)
   - Execution directive requirements
   - Task invocation patterns
   - Subprocess isolation requirements
   - State persistence patterns
   - Path validation patterns
   - Output suppression requirements
   - Prohibited patterns

2. `/home/benjamin/.config/.claude/docs/concepts/patterns/error-handling.md` (963 lines)
   - Error classification taxonomy
   - JSONL schema
   - Dual trap setup pattern
   - Error lifecycle status
   - Test environment separation
   - State persistence integration
   - Recovery patterns

3. `/home/benjamin/.config/.claude/docs/reference/standards/code-standards.md` (499 lines)
   - General principles (UTF-8, emoji policy)
   - Language-specific standards
   - Command and agent architecture
   - Mandatory bash block sourcing pattern
   - Error logging requirements
   - Output suppression patterns
   - Directory creation anti-patterns

4. `/home/benjamin/.config/.claude/docs/concepts/hierarchical-agents-overview.md` (177 lines)
   - Hierarchical supervision
   - Behavioral injection
   - Metadata-only context passing
   - Single source of truth
   - Agent roles and communication flow
   - Context efficiency metrics

5. `/home/benjamin/.config/.claude/lib/core/state-persistence.sh` (1,041 lines)
   - init_workflow_state() function
   - load_workflow_state() function
   - append_workflow_state() function
   - validate_state_file() function
   - JSON checkpoint functions
   - Pre-flight function validation

### Integration Points Summary

| Infrastructure System | Integration Method | Compliance Standard | Enforcement |
|----------------------|-------------------|---------------------|-------------|
| State Persistence | state-persistence.sh sourcing + workflow state API | Three-tier sourcing, fail-fast handlers | Pre-commit hooks (ERROR) |
| Error Logging | error-handling.sh + log_command_error() | Dual trap setup, 80% coverage target | Linter + manual review |
| Command Authoring | Execution directives + Task patterns | Imperative directives, no naked Task blocks | Linter (ERROR) |
| Hierarchical Agents | Behavioral injection + metadata passing | Hard barrier pattern, 95% context reduction | Integration tests |
| Code Quality | Automated validators + pre-commit hooks | Library sourcing, error suppression, conditionals | Pre-commit hooks (ERROR) |

### Performance Targets

- **Context Reduction**: 95%+ (10,000 → 440 tokens for 4-topic research)
- **Time Savings**: 40-60% (parallel vs sequential execution)
- **State Persistence Overhead**: <15ms (CLAUDE_PROJECT_DIR detection)
- **Error Logging Coverage**: 80%+ of error exit points
- **Test Pass Rate**: 100% (all automated tests passing)

### Next Steps

1. **Implementation Phase**: Integrate all mandatory patterns into /research command
2. **Validation Phase**: Run all validators and automated tests
3. **Performance Phase**: Measure context reduction and time savings
4. **Documentation Phase**: Update command guide and CLAUDE.md sections
5. **Review Phase**: Manual code review for compliance checklist completion

---

**Research Complete**: Infrastructure integration requirements documented with 100% coverage of state persistence, error logging, command authoring, hierarchical agents, and code quality enforcement standards.
