# Feature Preservation Failure Modes Research Report

## Metadata
- **Date**: 2025-11-17
- **Agent**: research-specialist
- **Topic**: Feature Preservation Failure Modes in Dedicated Orchestrator Commands
- **Report Type**: risk analysis and integration analysis
- **Plan Reference**: [001_dedicated_orchestrator_commands.md](../../../743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md)
- **Overview Report**: [OVERVIEW.md](./OVERVIEW.md)

## Executive Summary

The plan to extract 5 dedicated orchestrator commands from /coordinate faces 8 critical feature preservation failure modes across integration risks, backward compatibility concerns, and edge cases. Key risks include adaptive planning integration loss (checkpoint recovery, auto-resume from most recent incomplete plan), hierarchical supervision threshold inconsistency (≥4 topics vs complexity ≥8), workflow-classifier bypass implications (loss of semantic analysis for research topic generation), and state machine library dependency coupling (breaking changes require coordinated migration across all 5+ commands). The plan's Phase 7 backward compatibility maintenance is insufficient, requiring explicit migration path validation, deprecation timeline specification, and coordinated command development to prevent workflow fragmentation.

## Findings

### 1. Adaptive Planning Integration Risks (Feature Loss Category)

**Risk**: Adaptive planning features may be lost or inconsistently implemented across new commands.

**Analysis**: The /implement command provides sophisticated adaptive planning capabilities that are referenced but not fully specified in the new command plan:

#### 1.1 Auto-Resume from Most Recent Incomplete Plan

**Location**: `/home/benjamin/.config/.claude/commands/implement.md:84-98`

The /implement command implements two-tier auto-resume strategy:
```bash
# Tier 1: Load from checkpoint if exists
CHECKPOINT_DATA=$(load_checkpoint "implement")
if [ $? -eq 0 ]; then
  if check_safe_resume_conditions "$CHECKPOINT_FILE"; then
    PLAN_FILE=$(echo "$CHECKPOINT_DATA" | jq -r '.plan_path')
    STARTING_PHASE=$(echo "$CHECKPOINT_DATA" | jq -r '.current_phase')
    echo "✓ Auto-resuming from Phase $STARTING_PHASE"
  fi
fi

# Tier 2: Find most recent incomplete plan if no checkpoint
if [ -z "$PLAN_FILE" ]; then
  PLAN_FILE=$(find . -path "*/specs/plans/*.md" -type f -exec ls -t {} + 2>/dev/null | head -1)
fi
```

**Failure Mode in New Plan**:
- `/build` command (Phase 4) specifies "auto-resume with two-tier strategy" but doesn't clarify:
  - What constitutes "safe resume conditions" (authorship check? git status verification?)
  - How to handle checkpoint vs most-recent-plan conflicts
  - Whether checkpoint takes precedence over user-provided plan path argument
  - Checkpoint compatibility across command versions (if checkpoint created by /coordinate, can /build resume?)

**Missing from Plan**: Lines 325-349 of plan mention "auto-resume" but provide no detailed specification comparable to /implement's implementation.

#### 1.2 Checkpoint Recovery Validation

**Location**: `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md:232-272`

Checkpointing system defines specific safety checks before resume:
- Checkpoint age verification (< 7 days)
- Workflow description matching (for /coordinate)
- Plan path existence validation
- Git working tree clean state (no uncommitted changes)
- Phase boundary consistency (checkpoint phase ≤ total phases)

**Failure Mode in New Plan**:
- Phase 4 expansion (1,591 lines) mentions checkpoint validation but doesn't specify:
  - Which safety checks apply to /build (plan path only? no workflow description matching?)
  - How to handle checkpoint created by /coordinate for research-and-plan workflow
  - Whether /build can resume from /implement checkpoint or vice versa
  - Checkpoint migration strategy if state format changes

**Impact**: Users may lose work if auto-resume fails silently or resumes from incompatible checkpoint.

#### 1.3 Progressive Plan Structure Detection

**Location**: `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md:46-135`

Plans support 3 structure levels (L0/Tier 1: single file, L1/Tier 2: phase directory, L2/Tier 3: hierarchical tree). Commands must detect structure level before parsing:

```bash
PLAN_LEVEL=$(.claude/lib/parse-adaptive-plan.sh detect_structure_level "$PLAN_FILE")
TOTAL_PHASES=$(.claude/lib/parse-adaptive-plan.sh count_phases "$PLAN_FILE")
```

**Failure Mode in New Plan**:
- Phase 4 (/build command) mentions parse-adaptive-plan.sh usage but doesn't specify:
  - How to handle plans mid-migration (Tier 1 → Tier 2 expansion in progress)
  - Whether /build supports all 3 tiers or only specific tiers
  - What happens if plan structure changes between checkpoint save and resume
  - Handling of expanded phase files (phase_1_setup.md) vs inline phases

**Cross-Reference**: Plan line 101-102 mentions "parse-adaptive-plan.sh" but no validation that all tier levels supported.

### 2. Hierarchical Supervision Threshold Inconsistency (Integration Risk)

**Risk**: Inconsistent complexity thresholds for hierarchical vs flat coordination across workflows.

**Analysis**: The plan specifies two different threshold patterns that create ambiguity:

#### 2.1 Research Complexity Threshold (≥4 Topics)

**Location**: Plan lines 146-153, 221-223

```bash
# Default complexity per workflow type
/report: Default complexity 2
/research-plan: Default complexity 3
/research-revise: Default complexity 2
/build: N/A (no research phase)
/fix: Default complexity 2

# From feature preservation report (line 221-223 of plan)
Hierarchical threshold (≥4 topics) preserved in all commands
research-sub-supervisor agent used for complexity ≥4
Flat coordination for complexity <4
```

**Threshold**: Research complexity ≥4 triggers hierarchical supervision.

#### 2.2 Implementation Complexity Threshold (Score ≥8)

**Location**: `/home/benjamin/.config/.claude/commands/implement.md:136-142`

```bash
# Implementation research for complex phases (score ≥8 or tasks >10)
if [ "$COMPLEXITY_SCORE" -ge 8 ] || [ "$TASK_COUNT" -gt 10 ]; then
  echo "PROGRESS: Complex phase - invoking implementation researcher"
  # Invoke implementation-researcher agent
fi
```

**Threshold**: Phase complexity score ≥8 OR task count >10 triggers hierarchical coordination.

**Failure Mode**:
- Research phase uses topic count (≥4) but implementation phase uses complexity score (≥8)
- No specification how to reconcile when research complexity=3 but implementation complexity=9
- /build command inherits implementation logic but plan doesn't clarify if research threshold (≥4) applies
- Users may observe different coordination strategies across phases with similar complexity

**Missing Specification**: Plan Phase 4 mentions "hierarchical supervision threshold" but doesn't define:
- Whether /build uses research threshold (≥4 topics) or implementation threshold (≥8 complexity)
- How thresholds interact when workflow transitions from research → implementation
- Whether complexity scoring algorithm is consistent across research and implementation

### 3. Workflow Classifier Bypass Implications (Feature Loss Category)

**Risk**: Skipping workflow-classifier agent loses semantic analysis capabilities that may be used for purposes beyond workflow type selection.

**Analysis**: The plan's core premise is eliminating workflow-classifier to save 5-10s latency:

**Location**: Plan lines 19-21, 111-131

```markdown
The /coordinate command currently handles 5 distinct workflow types through initial
AI-based classification, which adds 5-10 seconds latency...

### Workflow Type Hardcoding (replaces classification):
# /research command
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
```

#### 3.1 Research Topic Generation Loss

**Location**: `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/002_distinct_workflows_in_coordinate.md:31-37`

Workflow classifier performs semantic analysis to generate research topics:
- Topic count matches complexity exactly (complexity=3 → 3 topics)
- Each topic has: short_name, detailed_description, filename_slug, research_focus
- Topics generated via LLM semantic analysis of workflow description

**Example Classification Output**:
```json
{
  "workflow_type": "research-and-plan",
  "research_complexity": 3,
  "research_topics": [
    {
      "short_name": "Authentication",
      "detailed_description": "OAuth2 and session-based auth patterns",
      "filename_slug": "authentication_patterns",
      "research_focus": "Security, token management, session lifecycle"
    },
    {
      "short_name": "Authorization",
      "detailed_description": "Role-based access control (RBAC) implementation",
      "filename_slug": "authorization_rbac",
      "research_focus": "Permission models, role hierarchies"
    },
    {
      "short_name": "User Management",
      "detailed_description": "User registration, profile management",
      "filename_slug": "user_management",
      "research_focus": "CRUD operations, validation, password policies"
    }
  ]
}
```

**Failure Mode in New Plan**:
- Plan Phase 1 (template) and Phase 2 (/research command) don't specify how research topics are generated without classifier
- Users must manually specify topics for complexity >1, increasing cognitive load
- Loss of semantic decomposition (workflow description → structured research topics)
- No guidance on topic granularity (what constitutes "one topic"?)

**Missing from Plan**: Lines 145-172 specify complexity defaults but not topic generation strategy.

#### 3.2 Complexity Override Without Semantic Validation

**Location**: Plan lines 154-172

```bash
# Support both embedded and explicit flag formats:
# - Embedded: /research "auth patterns --complexity 4"
# - Explicit: /research --complexity 4 "auth patterns"
if [[ "$WORKFLOW_DESCRIPTION" =~ --complexity[[:space:]]+([1-4]) ]]; then
  RESEARCH_COMPLEXITY="${BASH_REMATCH[1]}"
fi
```

**Issue**: Users can override complexity but plan doesn't specify:
- Whether topic count must match complexity (consistency requirement from classifier)
- How to generate appropriate number of topics for overridden complexity
- Validation that workflow description is suitable for requested complexity
  - Example: "/research 'fix typo in README.md' --complexity 4" (invalid - trivial task with high complexity)

**Workflow Classifier Validation** (now lost):
```markdown
# From workflow-classifier.md behavioral file
Validation Rules:
- Reject complexity 4 for single-topic workflows
- Reject complexity 1 for workflows mentioning multiple distinct areas
- Ensure topic count exactly matches complexity
```

**Failure Mode**: Users can specify mismatched complexity/topic combinations, resulting in:
- Wasted agent invocations (4 agents researching same narrow topic)
- Under-researched complex workflows (complexity 1 for multi-faceted feature)
- No automatic validation or correction

### 4. State Machine Library Dependency Coupling (Integration Risk)

**Risk**: Breaking changes to state machine libraries require coordinated migration across all dependent commands.

**Analysis**: Plan relies heavily on library reuse strategy for feature preservation:

**Location**: Plan lines 327-340

```markdown
Existing Libraries (from .claude/lib/):
- workflow-state-machine.sh (state management)
- state-persistence.sh (GitHub Actions pattern)
- dependency-analyzer.sh (wave calculation)
- metadata-extraction.sh (context reduction)
- verification-helpers.sh (checkpoint validation)
- error-handling.sh (fail-fast error messages)
```

#### 4.1 Library API Stability Requirements

**Current State Machine API** (`/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-200`):

```bash
# Core functions used by commands:
sm_init() {
  # Parameters: description, command_name, workflow_type, research_complexity, research_topics_json
  # Initializes state machine with 5 parameters
}

sm_transition() {
  # Parameters: next_state
  # Validates transition against STATE_TRANSITIONS table
  # Saves checkpoint atomically
}

STATE_TRANSITIONS=(
  [initialize]="research"
  [research]="plan,complete"        # research-only can skip to complete
  [plan]="implement,complete"       # research-and-plan can skip to complete
  [implement]="test"
  [test]="debug,document"           # Conditional branching
  [debug]="test,complete"           # Retry or give up
  [document]="complete"
  [complete]=""                     # Terminal state
)
```

**Failure Mode in New Plan**:
- If workflow-state-machine.sh changes sm_init() signature (adds 6th parameter for new feature), ALL 5 new commands break simultaneously
- No version locking or compatibility layer specified in plan
- Phase 1 template versioning (v1.0.0) doesn't specify library version dependencies
- Phase 6 validation script checks feature presence but not library version compatibility

**Missing from Plan**: Lines 440-451 mention "library stability guarantees" in recommendations but Phase 1 deliverable (template v1.0.0) doesn't include:
- Required library versions (workflow-state-machine.sh ≥ v2.0.0)
- Compatibility matrix (template v1.0.0 compatible with state machine v2.0.0-v2.5.0)
- Migration guide for library upgrades

#### 4.2 State Persistence Format Changes

**Current State File Format** (GitHub Actions pattern):

```bash
# /home/benjamin/.config/.claude/tmp/workflow_$$.sh
export WORKFLOW_ID="coordinate_1699356030"
export WORKFLOW_DESCRIPTION="research auth patterns"
export CURRENT_STATE="research"
export COMPLETED_STATES_JSON='["initialize"]'
export COMPLETED_STATES_COUNT=1
export RESEARCH_COMPLEXITY=3
export RESEARCH_TOPICS_JSON='[{"short_name":"Authentication",...}]'
```

**Failure Mode**:
- If state-persistence.sh changes from GitHub Actions format to JSON file format, checkpoints become unreadable
- Commands reading state from old format (COMPLETED_STATES_JSON) fail when format migrates
- No state format versioning specified (state file has no version field)

**Cross-Reference**: Plan line 335 mentions state-persistence.sh but Phase 1 compatibility script doesn't validate:
- State file format version
- Backward compatibility with old checkpoints (can new commands resume from old checkpoints?)

### 5. Backward Compatibility Maintenance Gaps (Backward Compatibility Category)

**Risk**: Insufficient specification for maintaining /coordinate backward compatibility while migrating users to new commands.

**Analysis**: Plan Phase 7 addresses backward compatibility but lacks critical details:

**Location**: Plan lines 416-456

```markdown
### Phase 7: Documentation and Backward Compatibility

Tasks:
- [ ] Add deprecation notice to /coordinate command (recommend dedicated commands)
- [ ] Update CLAUDE.md PROJECT_COMMANDS section with new commands
- [ ] Test /coordinate still functional (backward compatibility verification)
- [ ] Add migration guide from /coordinate to dedicated commands
```

#### 5.1 Deprecation Timeline Not Specified

**Issue**: Plan says "deprecation notice" but doesn't specify:
- Is /coordinate immediately deprecated or soft-deprecated (warning but still supported)?
- Timeline for full removal (6 months? 1 year? never?)
- What happens to existing /coordinate checkpoints after deprecation?
- Whether new features go into /coordinate or only new commands

**Comparison to /implement**:
```bash
# /implement has no deprecation mechanism - it's the canonical implementation command
# No example deprecation timeline in codebase to follow
```

**Failure Mode**: Users may continue using /coordinate indefinitely if no clear migration pressure, preventing benefit realization of dedicated commands.

#### 5.2 Checkpoint Migration Strategy Missing

**Issue**: Users with existing /coordinate checkpoints face migration challenges:

**Checkpoint Format** (from adaptive-planning-guide.md:209-229):
```json
{
  "checkpoint_id": "orchestrate_auth_system_20251003_184530",
  "workflow_type": "orchestrate",  // Not "coordinate"
  "project_name": "auth_system",
  "workflow_description": "Implement authentication system",
  "current_phase": 2,
  "total_phases": 5,
  "completed_phases": [1],
  "workflow_state": {
    "project_name": "auth_system",
    "artifact_registry": {...},
    "research_results": [...],
    "plan_path": "specs/plans/022_auth_implementation.md"
  }
}
```

**Questions Not Addressed**:
- Can /build resume from a /coordinate checkpoint with workflow_type="full-implementation"?
- Can /research-plan resume from /coordinate checkpoint with workflow_type="research-and-plan"?
- What happens to checkpoints referencing deprecated /coordinate command?
- Should checkpoint migration utility convert old checkpoints to new command format?

**Missing from Plan**: Phase 7 testing includes "verify /coordinate still functional" but not:
- Cross-command checkpoint compatibility testing
- Checkpoint migration utility development
- Checkpoint format versioning for future migrations

#### 5.3 Feature Parity Validation Gap

**Issue**: Plan assumes new commands preserve all /coordinate features but doesn't specify validation:

**Feature Parity Checklist** (from feature preservation report):
1. Wave-based parallel execution (40-60% time savings)
2. State machine architecture (validated transitions)
3. Context reduction via hierarchical supervisors (95.6%)
4. Metadata extraction (200-300 tokens per agent)
5. Behavioral injection (100% file creation reliability)
6. Verification checkpoints (fail-fast error handling)

**Missing from Plan**: Phase 7 says "verify /coordinate still functional" but doesn't require:
- Feature parity validation between /coordinate and equivalent new command
  - Example: /coordinate "research auth" vs /research "research auth" produce identical outputs?
- Performance parity validation (latency reduction measured and documented)
- User experience parity (commands feel familiar to /coordinate users)

**Test Gap**: Phase 6 validation tests new commands in isolation but doesn't A/B test against /coordinate baseline.

### 6. Workflow Scope Detection Pattern Incompatibility (Integration Risk)

**Risk**: New commands hardcode workflow type but existing /revise command expects dynamic workflow scope detection.

**Analysis**: Plan proposes hardcoded workflow types for dedicated commands, but /revise command integration requires dynamic detection:

#### 6.1 /revise Command Integration

**Location**: `/home/benjamin/.config/.claude/commands/revise.md:1-100`

The /revise command operates in two modes:
1. Interactive mode: User provides revision description
2. Auto-mode: Invoked by other commands with structured JSON context

**Auto-Mode Invocation Pattern** (used by /implement):
```bash
# /implement detects test failures and auto-invokes /revise
/revise --auto-mode --context '{
  "revision_type": "test_failure_adaptation",
  "phase_number": 3,
  "reason": "Tests failed after implementation",
  "error_details": "..."
}'
```

**Failure Mode**: If /build invokes /revise in auto-mode, how does /revise know:
- Which plan to revise (/build took plan-path as argument, not workflow description)
- Whether to update plan structure (add debug phase? extend test phase?)
- What workflow context to use (full-implementation? build-only?)

**Missing from Plan**: Phase 4 (/build) mentions adaptive replanning but doesn't specify:
- How /build integrates with /revise command
- Whether /build can invoke /revise in auto-mode
- How revised plan paths are tracked across /build invocations

#### 6.2 Workflow Scope State Persistence

**Current Pattern** (`coordinate.md:365-380`):

```bash
# Workflow scope saved to state for cross-bash-block access
append_workflow_state "WORKFLOW_SCOPE" "$WORKFLOW_SCOPE"

# Later bash blocks reload scope
load_workflow_state "$WORKFLOW_ID"
# WORKFLOW_SCOPE now available
```

**Issue**: New commands hardcode workflow type at command level:
```bash
# /research command
WORKFLOW_TYPE="research-only"
TERMINAL_STATE="research"
```

But if /research needs to revise plan (unlikely but possible edge case), how does revision logic know original workflow scope?

**Failure Mode**: Scope hardcoding prevents dynamic scope adjustments needed for:
- Mid-workflow scope changes (research-only → research-and-plan if user requests plan creation)
- Workflow composition (chaining /research → /research-plan using same artifacts)
- Error recovery (falling back to simpler scope on failures)

### 7. Phase Conditional Execution Complexity (Edge Case Risk)

**Risk**: Complex conditional phase execution logic creates edge cases not covered by plan.

**Analysis**: Plan Phase 4 (/build command) implements most complex conditional logic:

**Location**: Plan lines 176-204

```bash
# After research phase
case "$COMMAND_NAME" in
  research)
    sm_transition "$STATE_COMPLETE"
    display_brief_summary
    exit 0
    ;;
  research-plan|research-revise)
    sm_transition "$STATE_PLAN"
    ;;
  build)
    sm_transition "$STATE_PLAN"
    ;;
  debug)
    sm_transition "$STATE_PLAN"
    ;;
esac
```

#### 7.1 Conditional Phase Branching Edge Cases

**/build Command Branching** (from plan Phase 4 summary):
- Test success → transition to document phase
- Test failure → transition to debug phase
- Debug success → retry test phase (max 2 attempts)
- Debug failure after 2 attempts → transition to complete (give up)

**Edge Cases Not Specified**:

1. **Debug Loop Prevention**: Plan says "max 2 debug attempts" but doesn't specify:
   - Counter persistence across bash blocks (how to track attempt count?)
   - What if first debug succeeds, second test fails again (reset counter or cumulative?)
   - Whether attempt limit is per-phase or per-workflow

2. **Partial Test Failures**: Plan doesn't specify behavior when:
   - 50% of tests pass (continue to document or debug?)
   - Tests pass but coverage drops (acceptable or block?)
   - Tests pass but linting fails (separate concern or bundled?)

3. **Document Phase Skipping**: Plan says "test success → document" but doesn't specify:
   - Whether document phase is optional (can user skip documentation?)
   - What if no documentation updates needed (auto-skip or error?)
   - Whether document phase creates git commit or just updates files

**Missing from Plan**: Phase 4 expansion (1,591 lines) should specify:
- State machine transition table for /build (explicitly enumerate all valid transitions)
- Edge case handling for partial failures
- Attempt counter persistence mechanism

#### 7.2 Resume from Mid-Phase Interruption

**Issue**: Plan supports checkpoint resume but doesn't specify behavior for mid-phase interruptions:

**Checkpoint Granularity** (from adaptive-planning-guide.md:179-191):
```
In /implement:
- After each phase completion (after git commit)
- Before moving to next phase
- On workflow pause or interruption
```

**Edge Case**: What if /build is interrupted during debug phase (between debug attempt 1 and 2)?
- Does resume restart debug from beginning (losing attempt 1 progress)?
- Does resume continue from attempt 2 (requires attempt counter in checkpoint)?
- How to detect mid-phase interruption vs phase completion?

**Missing from Plan**: Phase 4 checkpoint logic should specify:
- Checkpoint saves at phase boundaries only or mid-phase too?
- What state is saved for conditional phases (debug attempt count, test retry count)
- How to resume from each possible interruption point

### 8. Test Suite Integration Gaps (Edge Case Risk)

**Risk**: Test execution patterns vary across projects but plan assumes standardized test command discovery.

**Analysis**: Plan Phase 4 (/build) includes test execution:

**Location**: `/home/benjamin/.config/.claude/commands/implement.md:155-172`

```bash
# Run tests
TEST_COMMAND=$(echo "$TASK_LIST" | grep -oE '(npm test|pytest|\.\/run_all_tests\.sh|:TestSuite)' | head -1)
if [ -n "$TEST_COMMAND" ]; then
  echo "PROGRESS: Running tests: $TEST_COMMAND"
  TEST_OUTPUT=$($TEST_COMMAND 2>&1)
  TEST_EXIT_CODE=$?
fi
```

**Edge Cases Not Addressed**:

1. **Multiple Test Frameworks**: Project uses npm test (unit) + pytest (integration) + ./e2e_tests.sh (end-to-end)
   - Which test command runs? (first match only via grep | head -1)
   - Should all test types run or only one?
   - What if some test types pass but others fail?

2. **Parametrized Test Commands**: Tests require arguments (pytest -k test_auth --verbose)
   - Regex `(npm test|pytest)` matches bare `pytest` but not `pytest -k test_auth`
   - Plan doesn't specify how to handle test command arguments

3. **Non-Standard Test Patterns**: Custom test runners not in regex list
   - Example: `make test`, `cargo test`, `mvn test`
   - Grep pattern only matches 4 specific patterns
   - Other test commands silently skipped (tests not run but no error)

4. **Test Environment Setup**: Tests require environment variables or database seeding
   - No specification for pre-test setup phase
   - Test failures may be environmental, not code-related

**Missing from Plan**: Phase 4 should specify:
- Test discovery strategy (grep patterns, test frameworks supported)
- Multiple test suite handling (run all or first only)
- Test environment initialization
- Parametrized test command support

## Recommendations

### Recommendation 1: Implement Research Topic Auto-Generation Fallback for Workflow Classifier Removal

**Action**: Enhance Phase 1 template and Phase 2 /research command with heuristic-based topic generation to replace semantic analysis capabilities lost by removing workflow-classifier.

**Implementation**:

1. **Heuristic Topic Decomposition Algorithm** (Phase 1: Template, lines 400-500):
   ```bash
   # Auto-generate research topics from workflow description
   generate_research_topics() {
     local description="$1"
     local complexity="$2"

     # Heuristic 1: Extract nouns/noun phrases using basic NLP patterns
     # "research authentication and authorization patterns" → ["authentication", "authorization", "patterns"]

     # Heuristic 2: Split on conjunctions (and, or, with)
     # "OAuth2 with session management" → ["OAuth2", "session management"]

     # Heuristic 3: Match complexity count exactly
     # complexity=3 → select top 3 topics by salience

     # Output: JSON array matching workflow-classifier format
     echo '[
       {
         "short_name": "Authentication",
         "detailed_description": "Extracted from workflow description",
         "filename_slug": "authentication",
         "research_focus": "General analysis"
       },
       ...
     ]'
   }
   ```

2. **User Override Syntax** (Phase 2: /research command):
   ```bash
   # Explicit topic specification with --topics flag
   /research "auth system" --complexity 3 --topics "OAuth2,Sessions,RBAC"

   # Fallback to heuristic generation if --topics not provided
   RESEARCH_TOPICS_JSON=$(generate_research_topics "$WORKFLOW_DESCRIPTION" "$RESEARCH_COMPLEXITY")
   ```

3. **Validation Rules** (Phase 1: Template, lines 160-180):
   ```bash
   # Ensure topic count matches complexity
   TOPIC_COUNT=$(echo "$RESEARCH_TOPICS_JSON" | jq 'length')
   if [ "$TOPIC_COUNT" -ne "$RESEARCH_COMPLEXITY" ]; then
     echo "ERROR: Topic count ($TOPIC_COUNT) doesn't match complexity ($RESEARCH_COMPLEXITY)"
     echo "HINT: Use --topics flag to specify $RESEARCH_COMPLEXITY topics manually"
     exit 1
   fi
   ```

**Benefits**:
- Preserves semantic decomposition capability (heuristic vs LLM but still automatic)
- Reduces cognitive load vs requiring manual topic specification
- Maintains topic/complexity consistency validation
- Provides escape hatch (--topics flag) for precise control

**Trade-offs**:
- Heuristic topic generation less accurate than LLM semantic analysis
- May produce low-quality topics for ambiguous workflow descriptions
- Adds 50-100 lines of bash code to template

### Recommendation 2: Specify Hierarchical Supervision Threshold Unification Strategy

**Action**: Standardize complexity thresholds across research and implementation phases using unified complexity scoring algorithm.

**Implementation**:

1. **Unified Complexity Scoring Function** (Phase 1: Library enhancement):
   ```bash
   # .claude/lib/complexity-utils.sh enhancement
   calculate_unified_complexity_score() {
     local context_type="$1"  # "research" or "implementation"
     local input="$2"          # workflow description or phase content

     case "$context_type" in
       research)
         # Research complexity: Based on topic count and description breadth
         # Score = topic_count * 2 + semantic_breadth_factor
         # threshold ≥8 triggers hierarchical (equivalent to ≥4 topics)
         ;;
       implementation)
         # Implementation complexity: Based on task count and phase size
         # Score = task_count * 0.8 + file_count * 0.2
         # threshold ≥8 triggers hierarchical
         ;;
     esac

     echo "$score"
   }
   ```

2. **Template Integration** (Phase 1: Template, lines 500-550):
   ```bash
   # Research phase complexity evaluation
   RESEARCH_SCORE=$(calculate_unified_complexity_score "research" "$WORKFLOW_DESCRIPTION")

   # Hierarchical supervision decision (unified threshold: ≥8)
   if [ "$RESEARCH_SCORE" -ge 8 ]; then
     echo "PROGRESS: High complexity ($RESEARCH_SCORE ≥8), using hierarchical supervision"
     # Invoke research-sub-supervisor
   else
     echo "PROGRESS: Low complexity ($RESEARCH_SCORE <8), using flat coordination"
     # Invoke research-specialist agents directly
   fi
   ```

3. **Documentation Update** (Phase 7: Documentation):
   ```markdown
   # Complexity Threshold Standards

   All orchestration commands use unified threshold: **score ≥8** triggers hierarchical supervision.

   | Context | Score Calculation | Threshold | Coordination |
   |---------|------------------|-----------|--------------|
   | Research | topic_count × 2 + breadth | ≥8 (≥4 topics) | research-sub-supervisor |
   | Implementation | tasks × 0.8 + files × 0.2 | ≥8 | implementer-coordinator |
   | Testing | test_count × 1.0 | ≥8 | testing-sub-supervisor |
   ```

**Benefits**:
- Consistent user experience (same threshold across workflow phases)
- Unified complexity-utils.sh library (single source of truth)
- Clear documentation (one threshold to remember: ≥8)

**Trade-offs**:
- Research complexity scale (1-4) becomes internal implementation detail, not user-facing
- May require recalibrating research complexity defaults in Phase 2-5 commands

### Recommendation 3: Add Library Version Locking and Compatibility Matrix to Phase 1 Template

**Action**: Extend Phase 1 template versioning to include library dependency specifications and compatibility verification.

**Implementation**:

1. **Template Metadata Enhancement** (Phase 1: Template header):
   ```markdown
   ---
   template-version: 1.0.0
   library-dependencies:
     workflow-state-machine: ">=2.0.0,<3.0.0"
     state-persistence: ">=1.5.0,<2.0.0"
     dependency-analyzer: ">=1.0.0,<2.0.0"
     metadata-extraction: ">=1.2.0,<2.0.0"
     verification-helpers: ">=1.0.0,<2.0.0"
     error-handling: ">=1.1.0,<2.0.0"
   compatibility-matrix:
     coordinate: ">=1.0.0"  # Compatible with /coordinate v1.0.0+
     implement: ">=2.0.0"   # Compatible with /implement v2.0.0+
   ---
   ```

2. **Library Version Detection Script** (Phase 1: New deliverable):
   ```bash
   # .claude/lib/detect-library-version.sh
   detect_library_version() {
     local library_file="$1"

     # Extract version from library header comment
     # Format: # Version: 2.0.0
     grep "^# Version:" "$library_file" | sed 's/# Version: //'
   }

   verify_library_compatibility() {
     local library_name="$1"
     local required_version="$2"  # Format: ">=2.0.0,<3.0.0"
     local actual_version=$(detect_library_version ".claude/lib/${library_name}.sh")

     # Semver comparison logic
     # Return 0 if compatible, 1 if incompatible
   }
   ```

3. **Compatibility Verification in Template** (Phase 1: Template, lines 100-150):
   ```bash
   # CRITICAL: Verify library compatibility before proceeding
   source "${LIB_DIR}/detect-library-version.sh"

   for lib in workflow-state-machine state-persistence dependency-analyzer; do
     if ! verify_library_compatibility "$lib" "${REQUIRED_VERSIONS[$lib]}"; then
       echo "ERROR: Incompatible library version: $lib"
       echo "  Required: ${REQUIRED_VERSIONS[$lib]}"
       echo "  Found: $(detect_library_version "${LIB_DIR}/${lib}.sh")"
       echo "  Action: Update library or downgrade template version"
       exit 1
     fi
   done

   echo "✓ All library dependencies compatible"
   ```

4. **Library Versioning Enforcement** (Phase 1: New requirement):
   - All libraries in .claude/lib/ MUST include version header comment
   - Libraries MUST follow semantic versioning (major.minor.patch)
   - Breaking changes MUST increment major version
   - Template documentation MUST include library upgrade migration guide

**Benefits**:
- Prevents silent breakage from library updates (fail-fast on incompatibility)
- Enables gradual migration (commands lock to compatible library versions)
- Clear upgrade path (template version → required library versions)
- Supports rollback (can run old template with old libraries)

**Trade-offs**:
- Adds complexity to library maintenance (version management overhead)
- Requires semver comparison logic (50-100 lines of bash)
- May delay library upgrades (commands locked to old versions)

### Recommendation 4: Design Cross-Command Checkpoint Migration Utility for Backward Compatibility

**Action**: Add checkpoint migration utility to Phase 7 to enable seamless transition from /coordinate to dedicated commands.

**Implementation**:

1. **Checkpoint Format Versioning** (Phase 7: Checkpoint schema update):
   ```json
   {
     "checkpoint_version": "2.0.0",  // NEW: Version field for migration
     "checkpoint_id": "coordinate_auth_system_20251003_184530",
     "workflow_type": "full-implementation",
     "command_name": "coordinate",   // NEW: Which command created checkpoint
     "compatible_commands": ["build"],  // NEW: Which commands can resume
     "project_name": "auth_system",
     "workflow_description": "Implement authentication system",
     "current_phase": 2,
     "total_phases": 5,
     "completed_phases": [1],
     "workflow_state": { ... }
   }
   ```

2. **Migration Utility Script** (Phase 7: New deliverable):
   ```bash
   # .claude/lib/checkpoint-migration.sh
   migrate_checkpoint_to_command() {
     local checkpoint_file="$1"
     local target_command="$2"  # "build", "research-plan", etc.

     # Load checkpoint
     CHECKPOINT_DATA=$(cat "$checkpoint_file")
     CHECKPOINT_VERSION=$(echo "$CHECKPOINT_DATA" | jq -r '.checkpoint_version // "1.0.0"')
     SOURCE_COMMAND=$(echo "$CHECKPOINT_DATA" | jq -r '.command_name // "coordinate"')

     # Validate migration compatibility
     if ! is_migration_compatible "$SOURCE_COMMAND" "$target_command" "$CHECKPOINT_VERSION"; then
       echo "ERROR: Cannot migrate checkpoint from $SOURCE_COMMAND to $target_command"
       echo "  Checkpoint version: $CHECKPOINT_VERSION"
       echo "  Incompatible due to: $(get_incompatibility_reason)"
       return 1
     fi

     # Perform migration transformations
     # - Update command_name field
     # - Update compatible_commands list
     # - Migrate state format if needed (v1.0.0 → v2.0.0)
     # - Preserve workflow_state, current_phase, completed_phases

     # Save migrated checkpoint
     echo "$MIGRATED_CHECKPOINT" > "$checkpoint_file.migrated"
     echo "✓ Checkpoint migrated: $checkpoint_file.migrated"
   }
   ```

3. **Auto-Migration in /build Command** (Phase 4: Auto-resume enhancement):
   ```bash
   # Tier 1: Load from checkpoint (with auto-migration)
   CHECKPOINT_DATA=$(load_checkpoint "build")
   if [ $? -ne 0 ]; then
     # Try loading /coordinate checkpoint and migrating
     COORDINATE_CHECKPOINT=$(load_checkpoint "coordinate")
     if [ $? -eq 0 ]; then
       echo "Found /coordinate checkpoint, attempting migration..."
       if migrate_checkpoint_to_command "$COORDINATE_CHECKPOINT" "build"; then
         CHECKPOINT_DATA=$(cat "$COORDINATE_CHECKPOINT.migrated")
         echo "✓ Successfully migrated /coordinate checkpoint to /build"
       else
         echo "⚠ Migration failed, starting fresh"
       fi
     fi
   fi
   ```

4. **Compatibility Matrix** (Phase 7: Documentation):
   ```markdown
   # Checkpoint Migration Compatibility

   | Source Command | Target Command | Compatible | Notes |
   |---------------|----------------|-----------|-------|
   | /coordinate (research-only) | /research | ✓ | Direct migration |
   | /coordinate (research-and-plan) | /research-plan | ✓ | Direct migration |
   | /coordinate (research-and-revise) | /research-revise | ✓ | Requires existing plan path |
   | /coordinate (full-implementation) | /build | ✓ | Requires plan file creation |
   | /coordinate (debug-only) | /fix | ✓ | Direct migration |
   | /implement | /build | ✓ | Implementation phase onwards |
   | /build | /coordinate | ✗ | Incompatible (workflow type hardcoded) |
   ```

**Benefits**:
- Seamless user transition (no manual checkpoint cleanup required)
- Preserves work in progress (users can switch commands mid-workflow)
- Clear compatibility documentation (users know what migrations work)
- Supports future migrations (checkpoint version field enables v2.0.0 → v3.0.0)

**Trade-offs**:
- Adds 200-300 lines of migration logic
- Checkpoint format changes require migration code updates
- May cause confusion if migration fails silently

### Recommendation 5: Add Comprehensive Edge Case Test Suite to Phase 6 Validation

**Action**: Extend Phase 6 feature preservation validation to include edge case testing specifically for conditional phase execution, mid-phase interruption, and test framework discovery.

**Implementation**:

1. **Edge Case Test Categories** (Phase 6: Test suite extension):

   **Category 1: Conditional Phase Branching Edge Cases** (5 tests):
   ```bash
   # Test 1.1: Debug loop prevention (max 2 attempts)
   test_debug_loop_prevention() {
     # Setup: Plan with failing tests
     # Execute: /build with tests that fail 3 times
     # Assert: Debug runs twice, then workflow completes with failure status
     # Assert: Attempt counter persists across bash blocks
   }

   # Test 1.2: Partial test failures (50% pass rate)
   test_partial_test_failure_handling() {
     # Setup: Test suite with 10 tests, 5 pass, 5 fail
     # Execute: /build
     # Assert: Workflow transitions to debug (not document)
     # Assert: Debug receives partial failure context
   }

   # Test 1.3: Document phase skipping (no changes needed)
   test_document_phase_auto_skip() {
     # Setup: Implementation with no documentation updates
     # Execute: /build (tests pass)
     # Assert: Document phase checks for changes needed
     # Assert: Auto-skips if no documentation affected
   }

   # Test 1.4: Test success after debug retry
   test_debug_retry_success() {
     # Setup: Tests fail initially, pass after debug fix
     # Execute: /build → test failure → debug → test retry
     # Assert: Workflow transitions to document (not debug again)
     # Assert: Attempt counter resets after success
   }

   # Test 1.5: Mid-conditional-branch interruption
   test_mid_branch_interruption_recovery() {
     # Setup: Interrupt /build during debug phase (between attempts)
     # Execute: Resume /build
     # Assert: Resumes from beginning of debug phase OR continues from attempt N
     # Assert: Checkpoint includes conditional branch state
   }
   ```

   **Category 2: Checkpoint Resume Edge Cases** (4 tests):
   ```bash
   # Test 2.1: Resume from /coordinate checkpoint with /build
   test_cross_command_checkpoint_resume() {
     # Setup: Create /coordinate checkpoint at plan phase
     # Execute: /build (no args, auto-resume)
     # Assert: Detects /coordinate checkpoint, attempts migration
     # Assert: Resumes from plan phase using /build logic
   }

   # Test 2.2: Checkpoint with modified plan structure
   test_checkpoint_with_plan_tier_migration() {
     # Setup: Checkpoint created with Tier 1 plan, plan migrated to Tier 2
     # Execute: Resume workflow
     # Assert: Detects plan structure change, re-parses plan
     # Assert: Phase numbering still consistent
   }

   # Test 2.3: Resume with incompatible library version
   test_resume_with_library_incompatibility() {
     # Setup: Checkpoint created with state-machine v2.0.0, library upgraded to v3.0.0
     # Execute: Resume workflow
     # Assert: Detects incompatibility, shows clear error
     # Assert: Suggests migration or library downgrade
   }

   # Test 2.4: Concurrent resume attempts (race condition)
   test_concurrent_checkpoint_resume() {
     # Setup: Two /build instances started simultaneously with same checkpoint
     # Execute: Both attempt resume
     # Assert: Lock file prevents double-resume
     # Assert: Second instance shows "checkpoint in use" error
   }
   ```

   **Category 3: Test Framework Discovery Edge Cases** (6 tests):
   ```bash
   # Test 3.1: Multiple test frameworks (npm + pytest)
   test_multiple_test_framework_handling() {
     # Setup: Plan with both "npm test" and "pytest" tasks
     # Execute: /build
     # Assert: Both test commands executed OR only first OR error
     # Document: Clarify expected behavior in plan
   }

   # Test 3.2: Parametrized test command (pytest -k test_auth)
   test_parametrized_test_command() {
     # Setup: Plan task with "Run tests: pytest -k test_auth --verbose"
     # Execute: /build
     # Assert: Full command executed (not just "pytest")
     # Assert: Parameters preserved
   }

   # Test 3.3: Non-standard test runner (make test)
   test_nonstandard_test_pattern() {
     # Setup: Plan task with "make test"
     # Execute: /build
     # Assert: Test discovery fails OR custom pattern added
     # Document: List all supported test patterns
   }

   # Test 3.4: Test environment setup required
   test_environment_setup_before_tests() {
     # Setup: Tests require DB_URL environment variable
     # Execute: /build
     # Assert: Test setup phase runs before test execution
     # Assert: Environment variables available to test process
   }

   # Test 3.5: Test command in wrong task format
   test_malformed_test_task() {
     # Setup: Plan task "Testing using pytest framework" (no command)
     # Execute: /build
     # Assert: Test discovery fails with helpful error
     # Assert: Suggests correct task format
   }

   # Test 3.6: Test command produces non-zero exit but tests pass
   test_nonzero_exit_with_passing_tests() {
     # Setup: pytest exits with code 1 but all tests pass (linting warnings)
     # Execute: /build
     # Assert: Correctly interprets as success OR delegates to user
     # Document: Exit code interpretation strategy
   }
   ```

2. **Test Framework Enhancement** (Phase 6: Validation script update):
   ```bash
   # .claude/tests/validate_edge_cases.sh
   run_edge_case_test_suite() {
     local command_name="$1"  # "build", "research", etc.

     echo "=== Edge Case Test Suite: $command_name ==="

     # Category 1: Conditional branching
     for test in test_debug_loop_prevention test_partial_test_failure_handling \
                 test_document_phase_auto_skip test_debug_retry_success \
                 test_mid_branch_interruption_recovery; do
       run_test "$test" "$command_name" || {
         echo "FAILED: $test"
         FAILURES=$((FAILURES + 1))
       }
     done

     # Category 2: Checkpoint resume
     # Category 3: Test discovery
     # ...

     if [ "$FAILURES" -gt 0 ]; then
       echo "❌ $FAILURES edge case tests failed"
       return 1
     else
       echo "✓ All edge case tests passed"
       return 0
     fi
   }
   ```

3. **Phase 6 Acceptance Criteria Update**:
   - Add requirement: "All 15 edge case tests passing (5 branching + 4 checkpoint + 6 test discovery)"
   - Add deliverable: Edge case test report documenting each scenario and outcome
   - Add performance target: Edge case test suite completes in <5 minutes

**Benefits**:
- Proactive edge case discovery (find issues before production use)
- Regression prevention (edge case tests run in CI/CD)
- Clear behavior specification (tests document expected edge case handling)
- User confidence (comprehensive testing demonstrates robustness)

**Trade-offs**:
- Significant test development effort (15 tests × 50 lines = 750 lines)
- Test maintenance burden (update tests when command logic changes)
- May uncover specification gaps requiring plan revision

## References

- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/plans/001_dedicated_orchestrator_commands.md:1-585` - Plan file analyzed for feature preservation failure modes
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/003_feature_preservation_patterns.md:1-547` - Feature preservation patterns and 6 essential features
- `/home/benjamin/.config/.claude/specs/743_coordinate_command_working_reasonably_well_more/reports/002_distinct_workflows_in_coordinate.md:1-200` - Workflow classification system and 5 workflow types
- `/home/benjamin/.config/.claude/commands/coordinate.md:1-300` - Current coordinate command implementation with workflow classification
- `/home/benjamin/.config/.claude/commands/implement.md:1-200` - Implement command with auto-resume and adaptive planning
- `/home/benjamin/.config/.claude/commands/revise.md:1-100` - Revise command integration patterns
- `/home/benjamin/.config/.claude/docs/workflows/adaptive-planning-guide.md:1-477` - Adaptive planning system with checkpointing
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh:1-200` - State machine library API and architecture
- `/home/benjamin/.config/.claude/agents/research-sub-supervisor.md:1-150` - Hierarchical supervision pattern for research coordination
