# /supervise Command Structure Analysis

## Metadata
- **Date**: 2025-10-27
- **Agent**: research-specialist
- **Topic**: Analyze the /supervise command structure, organization, and core responsibilities
- **Report Type**: codebase analysis
- **Command File**: /home/benjamin/.config/.claude/commands/supervise.md
- **File Size**: 64KB (1,818 lines)

## Executive Summary

The /supervise command is a well-structured multi-agent orchestration system implementing a 7-phase workflow (Phase 0-6) with strong architectural discipline. The command exhibits excellent separation of concerns through behavioral injection patterns, comprehensive verification checkpoints (20 instances), and fail-fast error handling. The structure shows evidence of recent optimization work through consolidated library usage (workflow-initialization.sh reducing 350+ lines to ~100 lines). Core strengths include strict orchestrator role discipline (no direct file manipulation), mandatory verification at every phase boundary, and clear documentation of workflow scope types. The command could benefit from further consolidation of verification patterns and extraction of agent invocation templates.

## Findings

### 1. Overall Structure and Organization

**File Metrics** (supervise.md:1-1818):
- **Total Lines**: 1,818 lines
- **File Size**: 64KB
- **Phase Sections**: 7 major sections (Phase 0-6)
- **Subsections**: 33 level-3 headers (###)
- **Major Sections**: 12 level-2 headers (##)

**Structural Organization**:
```
Lines 1-43:     Front matter (YAML, role definition, architectural prohibitions)
Lines 44-109:   Architectural prohibition section (no command chaining)
Lines 110-237:  Workflow overview and specifications
Lines 238-377:  Shared utility functions (library sourcing)
Lines 378-439:  Available utility functions (API reference table)
Lines 440-594:  Phase 0 - Location and Path Pre-Calculation
Lines 595-911:  Phase 1 - Research (parallel agents, verification)
Lines 912-1149: Phase 2 - Planning (plan-architect agent)
Lines 1150-1279: Phase 3 - Implementation (code-writer agent)
Lines 1280-1384: Phase 4 - Testing (test-specialist agent)
Lines 1385-1710: Phase 5 - Debug (conditional, iterative)
Lines 1711-1799: Phase 6 - Documentation (conditional)
Lines 1800-1818: Workflow completion
```

**Section Markers** (supervise.md:442-1711):
- `[EXECUTION-CRITICAL]`: 7 instances marking sections that cannot be externalized
- `[REFERENCE-OK]`: 1 instance marking supplemental reference material
- Distinction helps identify which content must remain inline vs. can be documented externally

### 2. Phase Structure and Workflow Pattern

**7-Phase Sequential Workflow** (supervise.md:117-133):

Phase 0 is mandatory for all workflows (lines 440-594):
- Location detection and path pre-calculation
- Topic directory structure creation
- Artifact path export

Phases 1-6 are conditional based on workflow scope (lines 135-169):
1. **research-only**: Phases 0-1 (research reports + overview)
2. **research-and-plan**: Phases 0-2 (research + plan creation)
3. **full-implementation**: Phases 0-4, 6 (skip Phase 5 unless tests fail)
4. **debug-only**: Phases 0, 1, 5 (root cause analysis)

**Phase Execution Checks** (pattern appears 5 times):
```bash
should_run_phase N || {
  echo "⏭️  Skipping Phase N (name)"
  echo "  Reason: Workflow type is $WORKFLOW_SCOPE"
  # Exit or continue based on phase
}
```

**Verification Checkpoints** (20 instances throughout):
- Phase 0: Topic directory creation (line 217-268)
- Phase 1: Research reports (lines 686-842)
- Phase 2: Plan creation (lines 1007-1080)
- Phase 3: Implementation artifacts (lines 1206-1262)
- Phase 4: Test results (lines 1336-1382)
- Phase 5: Debug report (lines 1523-1542), iteration loop
- Phase 6: Summary creation (lines 1772-1794)

### 3. Orchestrator Role and Responsibilities

**YOUR ROLE Definition** (supervise.md:8-39):

The command explicitly defines orchestrator responsibilities vs. prohibitions:

**Orchestrator Responsibilities** (lines 11-17):
1. Pre-calculate ALL artifact paths before agent invocations
2. Determine workflow scope (4 types)
3. Invoke specialized agents via Task tool with context injection
4. Verify agent outputs at mandatory checkpoints
5. Extract and aggregate metadata from agent results
6. Report final workflow status and artifact locations

**Strict Prohibitions** (lines 19-24):
1. Execute tasks using Read/Grep/Write/Edit tools (except Phase 0 setup)
2. Invoke other commands via SlashCommand tool (/plan, /implement, /debug, /document)
3. Modify or create files directly (except Phase 0 setup)
4. Skip mandatory verification checkpoints
5. Continue workflow after verification failure

**Tools Allowed** (lines 31-35):
- Task: ONLY tool for agent invocations
- TodoWrite: Track phase progress
- Bash: Verification checkpoints (ls, grep, wc)
- Read: Parse agent output files for metadata extraction (NOT for task execution)

**Tools Prohibited** (lines 37-40):
- SlashCommand: NEVER invoke /plan, /implement, /debug, or any command
- Write/Edit: NEVER create artifact files (agents do this)
- Grep/Glob: NEVER search codebase directly (agents do this)

This represents excellent architectural discipline - the orchestrator truly delegates execution rather than performing work itself.

### 4. Library Dependencies and Utilities

**Required Libraries** (supervise.md:199-209):
All 7 libraries are mandatory with fail-fast error handling:

1. **workflow-detection.sh**: Scope detection, phase execution control
2. **error-handling.sh**: Error classification and recovery
3. **checkpoint-utils.sh**: Workflow resume capability
4. **unified-logger.sh**: Progress tracking
5. **unified-location-detection.sh**: Project structure location detection
6. **metadata-extraction.sh**: Artifact metadata extraction
7. **context-pruning.sh**: Context management

**Library Sourcing Pattern** (supervise.md:237-273):
Uses consolidated sourcing function from library-sourcing.sh:
```bash
source "$SCRIPT_DIR/../lib/library-sourcing.sh"
if ! source_required_libraries; then
  exit 1  # Fail-fast, no fallback
fi
```

**Available Utility Functions** (supervise.md:384-429):
13 core utility functions organized into 4 categories:

| Category | Functions | Purpose |
|----------|-----------|---------|
| Workflow Management | 2 | detect_workflow_scope(), should_run_phase() |
| Error Handling | 6 | classify_error(), suggest_recovery(), retry_with_backoff(), etc. |
| Checkpoint Management | 4 | save_checkpoint(), restore_checkpoint(), checkpoint_get/set_field() |
| Progress Logging | 1 | emit_progress() |

**Optimization: Consolidated Phase 0 Initialization** (supervise.md:565-593):

Recent consolidation reduced Phase 0 from 350+ lines to ~100 lines by extracting to workflow-initialization.sh:
```bash
source "$SCRIPT_DIR/../lib/workflow-initialization.sh"
if ! initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE"; then
  exit 1
fi
reconstruct_report_paths_array
```

This library implements the 3-step initialization pattern:
1. STEP 1: Scope detection (research-only, research+planning, full workflow)
2. STEP 2: Path pre-calculation (all artifact paths calculated upfront)
3. STEP 3: Directory structure creation (lazy: only topic root created)

### 5. Agent Invocation Pattern

**Agents Invoked** (6 specialized agents):
1. **research-specialist** (Phase 1): 2-4 parallel invocations based on complexity
2. **plan-architect** (Phase 2): Single invocation
3. **code-writer** (Phase 3 & Phase 5): Implementation and fix application
4. **test-specialist** (Phase 4): Test execution and reporting
5. **debug-analyst** (Phase 5): Root cause analysis
6. **doc-writer** (Phase 6): Summary creation

**Behavioral Injection Pattern** (appears 9 times with "EXECUTE NOW" directives):

Standard template structure (supervise.md:656-673):
```markdown
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Research [topic] with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/[agent-name].md

    **Workflow-Specific Context**:
    - [Context variable 1]: [Pre-calculated path]
    - [Context variable 2]: [Project standards]
    - [Context variable N]: [Additional context]

    **CRITICAL**: Before writing file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "[path]")"

    Execute [task] following all guidelines in behavioral file.
    Return: [COMPLETION_SIGNAL]: [path]
```

**No Command Chaining** (supervise.md:42-109):
Explicit architectural prohibition against using SlashCommand tool:
- ❌ INCORRECT: `SlashCommand { command: "/plan create auth feature" }`
- ✅ CORRECT: Direct agent invocation via Task tool with behavioral injection

**Benefits documented** (lines 82-87):
1. Lean context (200 lines vs 2000 lines)
2. Behavioral control (custom instructions, constraints)
3. Structured output (metadata not summaries)
4. Verification points (explicit checkpoints)

### 6. Verification and Error Handling

**Verification Pattern** (20 instances):

Standard verification structure:
```bash
echo "════════════════════════════════════════════════════════"
echo "  MANDATORY VERIFICATION - [Artifact Name]"
echo "════════════════════════════════════════════════════════"
echo ""

if retry_with_backoff 2 1000 test -f "$FILE_PATH" -a -s "$FILE_PATH"; then
  # Success path - quality checks
  echo "✅ VERIFICATION PASSED: [Artifact] created"
else
  # Failure path - error diagnostics
  ERROR_TYPE=$(detect_specific_error_type "$ERROR_MSG")
  ERROR_LOCATION=$(extract_error_location "$ERROR_MSG")

  if [ "$RETRY_DECISION" == "retry" ]; then
    # Single retry for transient errors
  else
    # Fail-fast for permanent errors
    echo "Workflow TERMINATED."
    exit 1
  fi
fi
```

**Auto-Recovery Strategy** (supervise.md:173-182):
- **Transient errors** (timeouts, file locks): Single retry after 1s delay
- **Permanent errors** (syntax, dependencies): Fail-fast with diagnostics
- **Partial research failure**: Continue if ≥50% agents succeed
- **Performance overhead**: <5% for recovery infrastructure

**Enhanced Error Reporting** (supervise.md:184-191):
- Error location extraction (file:line parsing)
- Error type categorization (timeout, syntax, dependency, unknown)
- Context-specific recovery suggestions
- >90% location extraction accuracy
- >85% type categorization accuracy

**Fail-Fast Design Philosophy** (supervise.md:197-216):
No bootstrap fallback mechanisms - all library dependencies are required:
- Clear, actionable error messages showing which library failed
- Diagnostic commands included in error output
- Function-to-library mapping shown when functions missing
- Immediate exit (no silent degradation)

Rationale: "Fallback mechanisms hide configuration errors and make debugging harder"

### 7. Context Management and Performance

**Performance Targets** (supervise.md:161-170):
- **Context Usage**: <25% throughout workflow
- **File Creation Rate**: 100% with auto-recovery
- **Recovery Rate**: >95% for transient errors
- **Performance Overhead**: <5% for recovery infrastructure
- **Enhanced Error Reporting**: <30ms per error (negligible)

**Metadata Extraction Pattern** (supervise.md:812-839):
After research verification, extract metadata for 95% context reduction:
```bash
declare -A REPORT_METADATA
for report_path in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  METADATA=$(extract_report_metadata "$report_path")
  REPORT_METADATA["$(basename "$report_path")"]="$METADATA"
done
```

Context reduction metrics logged:
- Full reports: ~N tokens (N = file_size / 4)
- Metadata only: ~250 tokens per report
- Reduction: 95%+ typical

**Forward Message Pattern** (supervise.md:945-954):
Planning phase receives metadata only, not full report content:
```bash
RESEARCH_METADATA_LIST=""
for report in "${SUCCESSFUL_REPORT_PATHS[@]}"; do
  metadata="${REPORT_METADATA[$report_basename]}"
  RESEARCH_METADATA_LIST+="- Path: $report\n"
  RESEARCH_METADATA_LIST+="  Metadata: $metadata\n"
done
```

This enables plan-architect to read full reports if needed while keeping orchestrator context lean.

**Checkpoint Resume** (supervise.md:218-224):
Automatic resume from last completed phase:
```bash
RESUME_DATA=$(restore_checkpoint "supervise" 2>/dev/null || echo "")
if [ -n "$RESUME_DATA" ]; then
  RESUME_PHASE=$(echo "$RESUME_DATA" | jq -r '.current_phase // empty')
  # Skip to resume phase
fi
```

Checkpoints saved after Phases 1-4 (lines 902, 1112, 1276, 1382).

### 8. Workflow Scope Detection

**4 Workflow Types** (supervise.md:135-159):

Implemented via workflow-detection.sh library:

1. **research-only**:
   - Keywords: "research [topic]" without "plan" or "implement"
   - Phases: 0-1 only
   - Output: Research reports + overview synthesis
   - No plan or summary created

2. **research-and-plan** (MOST COMMON):
   - Keywords: "research...to create plan", "analyze...for planning"
   - Phases: 0-2 only
   - Output: Research reports + implementation plan
   - No summary (no implementation occurred)

3. **full-implementation**:
   - Keywords: "implement", "build", "add feature"
   - Phases: 0-4, 6 (Phase 5 conditional on test failures)
   - Output: All artifacts including summary
   - Complete feature development

4. **debug-only**:
   - Keywords: "fix [bug]", "debug [issue]", "troubleshoot [error]"
   - Phases: 0, 1, 5 only
   - Output: Debug analysis report
   - No new plan or summary

**Scope Detection Logic** (supervise.md:502-562):
Maps scope to phase execution lists:
```bash
case "$WORKFLOW_SCOPE" in
  research-only)
    PHASES_TO_EXECUTE="0,1"
    SKIP_PHASES="2,3,4,5,6"
    ;;
  # ... other cases
esac
```

### 9. Conditional Phase Execution

**Phase 5 (Debug) Conditional Logic** (supervise.md:1397-1407):
Executes if tests failed OR workflow is debug-only:
```bash
if [ "$TESTS_PASSING" == "false" ] || [ "$WORKFLOW_SCOPE" == "debug-only" ]; then
  echo "Executing Phase 5: Debug"
else
  echo "⏭️  Skipping Phase 5 (Debug)"
  echo "  Reason: Tests passing, no debugging needed"
fi
```

**Phase 6 (Documentation) Conditional Logic** (supervise.md:1724-1735):
Executes only if implementation occurred:
```bash
if [ "$IMPLEMENTATION_OCCURRED" == "true" ]; then
  echo "Executing Phase 6: Documentation"
else
  echo "⏭️  Skipping Phase 6 (Documentation)"
  echo "  Reason: No implementation to document (scope: $WORKFLOW_SCOPE)"
  display_brief_summary
  exit 0
fi
```

**Research Overview Synthesis** (supervise.md:854-896):
Conditionally created based on workflow scope:
```bash
if should_synthesize_overview "$WORKFLOW_SCOPE" "$SUCCESSFUL_REPORT_COUNT"; then
  # Create OVERVIEW.md
else
  # Skip - plan-architect will synthesize reports
fi
```

Rationale: When planning follows research, the plan-architect synthesizes research reports, making separate OVERVIEW.md redundant.

### 10. Debug Iteration Loop

**Phase 5 Structure** (supervise.md:1412-1708):

Iterative debug cycle (max 3 iterations):
```bash
for iteration in 1 2 3; do
  # 1. Invoke debug-analyst agent
  # 2. Verify debug report created
  # 3. Invoke code-writer to apply fixes
  # 4. Re-run tests via test-specialist
  # 5. Check if tests passing
  # 6. Break if passing, continue if failing
done
```

**Escalation After 3 Iterations** (lines 1698-1705):
If tests still failing after 3 iterations:
- Emit warning about manual intervention required
- Continue to Phase 6 (Documentation) anyway
- Preserve debug reports for manual review

This prevents infinite loops while maintaining workflow continuity.

## Recommendations

### 1. Extract Verification Pattern to Shared Function

**Current State**: Verification pattern repeated 7 times with slight variations (lines 686-810, 1007-1080, 1206-1262, 1336-1382, 1523-1542, 1772-1794).

**Recommendation**: Create `verify_artifact_created()` function in verification-patterns.sh library:

```bash
# Usage: verify_artifact_created "artifact_name" "$FILE_PATH" "FILE|DIR" [min_size]
verify_artifact_created() {
  local artifact_name="$1"
  local file_path="$2"
  local artifact_type="$3"  # FILE or DIR
  local min_size="${4:-200}"  # Default 200 bytes

  echo "════════════════════════════════════════════════════════"
  echo "  MANDATORY VERIFICATION - $artifact_name"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Standard verification logic with retry, error handling, diagnostics
  # Returns 0 on success, 1 on failure
}
```

**Benefits**:
- Reduce code duplication (7 instances × ~40 lines = 280 lines → ~150 lines)
- Ensure consistent error handling across all verifications
- Centralize recovery logic updates
- Improve maintainability

**Impact**: ~130 line reduction, improved consistency

### 2. Extract Agent Invocation Templates to Template Files

**Current State**: 9 agent invocation templates embedded inline (lines 656-673, 975-997, 1174-1195, 1308-1325, 1423-1520, 1545-1630, 1742-1761).

**Recommendation**: Create `.claude/commands/templates/agent-invocation/` directory with template files:

```markdown
# research-agent-invocation.template.md
**EXECUTE NOW**: USE the Task tool with these parameters:

- subagent_type: "general-purpose"
- description: "Research {{TOPIC}} with mandatory file creation"
- prompt: |
    Read and follow ALL behavioral guidelines from: .claude/agents/research-specialist.md

    **Workflow-Specific Context**:
    - Research Topic: {{WORKFLOW_DESCRIPTION}}
    - Report Path: {{REPORT_PATH}}
    - Project Standards: {{STANDARDS_FILE}}
    - Complexity Level: {{RESEARCH_COMPLEXITY}}

    **CRITICAL**: Before writing report file, ensure parent directory exists:
    Use Bash tool: mkdir -p "$(dirname "{{REPORT_PATH}}")"

    Execute research following all guidelines in behavioral file.
    Return: REPORT_CREATED: {{REPORT_PATH}}
```

Then reference templates in command:
```markdown
{{include: .claude/commands/templates/agent-invocation/research-agent-invocation.template.md}}
```

**Benefits**:
- Reduce command file size (~150-200 lines)
- Enable template reuse across orchestration commands (/orchestrate, /coordinate, /supervise)
- Centralize agent invocation pattern updates
- Improve readability of orchestrator logic

**Note**: Templates must remain complete and copy-paste ready per Standard 3 (Command Architecture Standards).

**Impact**: ~180 line reduction, improved reusability

### 3. Consolidate Workflow Completion Display

**Current State**: Brief summary function (lines 276-305) and workflow completion section (lines 1800-1814) are separate.

**Recommendation**: Move `display_brief_summary()` to workflow-completion.sh library and expand to handle all completion scenarios:

```bash
# workflow-completion.sh
display_workflow_completion() {
  local workflow_scope="$1"
  local topic_path="$2"
  local -n report_paths="$3"  # nameref to array
  local plan_path="${4:-}"
  local summary_path="${5:-}"
  local debug_report="${6:-}"

  echo "════════════════════════════════════════════════════════"
  echo "         /supervise WORKFLOW COMPLETE"
  echo "════════════════════════════════════════════════════════"
  echo ""

  # Display scope-specific completion information
  # Clean up checkpoints on successful completion
  # Provide next steps guidance
}
```

**Benefits**:
- Single source of truth for completion display
- Consistent formatting across all exit points
- Easier to update completion logic
- Enable reuse in other orchestration commands

**Impact**: ~50 line reduction, improved consistency

### 4. Add Progress Markers Documentation Section

**Current State**: Progress markers mentioned (lines 228-234) but implementation dispersed throughout phases.

**Recommendation**: Add comprehensive section documenting all progress markers:

```markdown
## Progress Markers Reference

All phases emit progress markers at key milestones:

| Phase | Marker | Condition |
|-------|--------|-----------|
| 0 | "Detecting workflow scope..." | Always |
| 0 | "Pre-calculating artifact paths..." | Always |
| 0 | "Creating topic directory structure..." | Always |
| 1 | "Invoking N research agents in parallel" | Always |
| 1 | "Verifying research report N/M" | Per report |
| 1 | "Research complete (N/M succeeded)" | After verification |
| 2 | "Verifying implementation plan" | Always |
| ... | ... | ... |
```

**Benefits**:
- Developers understand expected progress output
- Easier to debug stalled workflows
- Document user-visible behavior
- Aid in troubleshooting

**Impact**: +40 lines, improved documentation

### 5. Consider Extracting Phase Logic to Separate Files

**Current State**: All 7 phases in single 1,818-line file.

**Consideration**: Extract each phase to separate file (phase-0-location.sh, phase-1-research.sh, etc.) and source conditionally.

**Benefits**:
- Improved navigability (find phase logic faster)
- Enable phase-specific testing
- Reduce cognitive load when editing single phase
- Parallel development on different phases

**Risks**:
- Increased file count (7 additional files)
- Potential for broken references if sourcing fails
- Need to maintain phase execution order
- Complexity of passing variables between phase files

**Recommendation**: DEFER this optimization until command exceeds 3,000 lines or phases become independently reusable across multiple commands. Current structure is maintainable.

**Impact**: No immediate change recommended

## References

### Primary Analysis Files
- `/home/benjamin/.config/.claude/commands/supervise.md` (1,818 lines)
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (374 lines)
- `/home/benjamin/.config/.claude/lib/workflow-detection.sh` (referenced)
- `/home/benjamin/.config/.claude/lib/error-handling.sh` (referenced)
- `/home/benjamin/.config/.claude/lib/checkpoint-utils.sh` (referenced)
- `/home/benjamin/.config/.claude/lib/unified-logger.sh` (referenced)
- `/home/benjamin/.config/.claude/lib/metadata-extraction.sh` (referenced)
- `/home/benjamin/.config/.claude/lib/context-pruning.sh` (referenced)

### Agent Behavioral Files Referenced
- `.claude/agents/research-specialist.md` (Phase 1)
- `.claude/agents/plan-architect.md` (Phase 2)
- `.claude/agents/code-writer.md` (Phase 3, 5)
- `.claude/agents/test-specialist.md` (Phase 4, 5)
- `.claude/agents/debug-analyst.md` (Phase 5)
- `.claude/agents/doc-writer.md` (Phase 6)

### Documentation Files Referenced
- `.claude/docs/guides/supervise-guide.md` (usage examples)
- `.claude/docs/reference/supervise-phases.md` (detailed phase documentation)
- `.claude/docs/concepts/patterns/verification-fallback.md` (verification pattern)
- `.claude/docs/concepts/patterns/checkpoint-recovery.md` (checkpoint pattern)
- `.claude/specs/438_analysis_of_supervise_command_refactor_plan_for_re/reports/001_analysis_of_supervise_command_refactor_plan_for_re_research/OVERVIEW.md` (historical refactor analysis)

### Key Pattern References
- Behavioral Injection Pattern (lines 42-109, 656-673)
- Verification-Fallback Pattern (lines 173-182, 686-810)
- Checkpoint Recovery Pattern (lines 218-224, checkpoints at lines 902, 1112, 1276, 1382)
- Forward Message Pattern (lines 812-839, 945-954)
- Fail-Fast Error Handling (lines 197-216)
