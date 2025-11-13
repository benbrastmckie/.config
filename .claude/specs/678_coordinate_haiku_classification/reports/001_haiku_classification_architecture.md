# Comprehensive Haiku-Based Workflow Classification Architecture

## Metadata
- **Date**: 2025-11-12
- **Agent**: research-specialist
- **Topic**: Haiku-based workflow classification implementation architecture
- **Report Type**: implementation analysis
- **Related Specs**: 678 (Haiku classification), 683 (Critical bug fixes), 670 (Original LLM integration)
- **Research Focus**: LLM-based classification architecture, integration patterns, technical decisions, and impact

## Executive Summary

Specs 678 and 683 completed a comprehensive overhaul of workflow classification in the /coordinate command, replacing all pattern matching with a single Claude Haiku 4.5 LLM call that determines workflow scope, research complexity, and descriptive subtopic names. The implementation eliminated false-positive classification issues, provided contextual topic names for research agents, and fixed critical bugs related to subprocess isolation. This represents the completion of Spec 670's incremental LLM integration strategy.

**Key Achievements**:
- Zero pattern matching for any classification dimension (scope, complexity, or subtopics)
- Single Haiku call (~450-500ms) replaces two classification operations
- Dynamic path allocation based on actual complexity (eliminates capacity/usage mismatch)
- Descriptive topic names improve research agent context (e.g., "Haiku classification implementation architecture" vs "Topic 1")
- Critical subprocess isolation bug fixed (command substitution breaking exports)

**Impact on Command Agent Optimization** (Spec 677): The comprehensive classification architecture provides the foundation for command-level agent optimization by exposing all workflow characteristics (scope, complexity, topics) to downstream systems in a single operation, enabling intelligent resource allocation and parallel execution strategies.

## Findings

### 1. LLM-Based Classification Architecture

#### 1.1 Three-Layer Architecture

The implementation uses a three-layer architecture for comprehensive classification:

**Layer 1: LLM Classifier** (`.claude/lib/workflow-llm-classifier.sh`)
- Entry point: `classify_workflow_llm_comprehensive()` (lines 99-146)
- Invokes Claude Haiku 4.5 model with comprehensive prompt
- Returns JSON with workflow_type, confidence, research_complexity, subtopics, reasoning
- Confidence threshold: 0.7 (configurable via WORKFLOW_CLASSIFICATION_CONFIDENCE_THRESHOLD)
- Timeout: 10 seconds (configurable via WORKFLOW_CLASSIFICATION_TIMEOUT)

**Layer 2: Hybrid Classifier** (`.claude/lib/workflow-scope-detection.sh`)
- Entry point: `classify_workflow_comprehensive()` (lines 50-106)
- Three modes: hybrid (default), llm-only, regex-only
- Hybrid mode: LLM first, automatic fallback to regex + heuristic on failure/low-confidence
- Fallback: `fallback_comprehensive_classification()` (lines 114-141) combines regex scope detection with heuristic complexity
- Zero operational risk: regex fallback ensures 100% availability

**Layer 3: State Machine Integration** (`.claude/lib/workflow-state-machine.sh`)
- Integration point: `sm_init()` function (lines 352-416)
- Calls `classify_workflow_comprehensive()` during initialization
- Parses JSON response to extract three dimensions
- Exports WORKFLOW_SCOPE, RESEARCH_COMPLEXITY, RESEARCH_TOPICS_JSON
- Descriptive topic fallback: generates contextual names when LLM returns generic "Topic N" patterns

**File Reference**: Implementation spans 3 files with ~300 lines of new code:
- `workflow-llm-classifier.sh`: Lines 99-200 (comprehensive prompt and parsing)
- `workflow-scope-detection.sh`: Lines 50-200 (hybrid mode and fallback)
- `workflow-state-machine.sh`: Lines 345-416 (state machine integration and descriptive fallback)

#### 1.2 Comprehensive Prompt Schema

The Haiku prompt requests three classification dimensions in a single call:

```json
{
  "task": "classify_workflow_comprehensive",
  "description": "<workflow description>",
  "valid_scopes": [
    "research-only",
    "research-and-plan",
    "research-and-revise",
    "full-implementation",
    "debug-only"
  ],
  "instructions": "Return: workflow_type (scope), confidence (0.0-1.0), research_complexity (1-4), subtopics (descriptive names matching complexity), reasoning. Focus on INTENT, not keywords."
}
```

**Key Design Decision**: The prompt emphasizes intent over keywords to avoid false positives like "research the refactor command" being classified as a refactoring task instead of research-only.

**File Reference**: `workflow-llm-classifier.sh` lines 167-182 (comprehensive prompt construction)

#### 1.3 Response Parsing and Validation

The response parser validates all three dimensions:

```bash
# Parse comprehensive JSON response
WORKFLOW_SCOPE=$(echo "$classification_result" | jq -r '.workflow_type // "full-implementation"')
RESEARCH_COMPLEXITY=$(echo "$classification_result" | jq -r '.research_complexity // 2')
RESEARCH_TOPICS_JSON=$(echo "$classification_result" | jq -c '.subtopics // []')

# Validation:
# - workflow_type must be one of valid_scopes
# - research_complexity must be 1-4
# - subtopics array length must match complexity
# - confidence must be >= 0.7 threshold
```

**Fallback Behavior**: If validation fails, the system falls back to regex classification for scope and heuristic calculation for complexity, with generic topic names ("Topic 1", "Topic 2").

**File Reference**: `workflow-state-machine.sh` lines 352-376 (parsing and validation), `workflow-scope-detection.sh` lines 114-141 (fallback implementation)

### 2. Integration with /coordinate Command

#### 2.1 State Machine Integration Pattern

The state machine integration follows a specific initialization sequence:

```bash
# coordinate.md initialization (Part 2, lines 163-168)

# CRITICAL: Call sm_init to export variables (no command substitution)
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# Variables now available via export:
# - WORKFLOW_SCOPE
# - RESEARCH_COMPLEXITY
# - RESEARCH_TOPICS_JSON

# Pass RESEARCH_COMPLEXITY to initialize_workflow_paths for dynamic allocation
initialize_workflow_paths "$WORKFLOW_DESCRIPTION" "$WORKFLOW_SCOPE" "$RESEARCH_COMPLEXITY"
```

**Critical Bug Fix (Spec 683)**: Commit 0000bec4 originally introduced command substitution `RESEARCH_COMPLEXITY=$(sm_init ...)` which created a subshell that prevented exports from reaching the parent shell. This was fixed in commit 1c72e904 by calling `sm_init` directly without command substitution.

**File Reference**: `.claude/commands/coordinate.md` lines 163-168 (sm_init call pattern), `.claude/docs/concepts/bash-block-execution-model.md` (subprocess isolation documentation)

#### 2.2 Dynamic Path Allocation

Spec 678 Phase 4 implemented dynamic path allocation based on RESEARCH_COMPLEXITY:

```bash
# workflow-initialization.sh (lines 312-344)

initialize_workflow_paths() {
  local complexity="$3"  # RESEARCH_COMPLEXITY parameter

  # Allocate EXACTLY $complexity paths (not hardcoded 4)
  for i in $(seq 1 "$complexity"); do
    local report_path="${TOPIC_PATH}/reports/$(printf "%03d" "$i")_${report_name}.md"
    export "REPORT_PATH_$((i-1))"="$report_path"
  done

  export REPORT_PATHS_COUNT="$complexity"
}
```

**Before**: Hardcoded allocation of 4 paths regardless of complexity (capacity/usage mismatch)
**After**: Dynamic allocation matching exact complexity (1-4 paths based on workflow needs)

**Impact**: Eliminates unused environment variables and resolves Issue 676 diagnostic confusion ("Saved 4 report paths" when only 2 are used).

**File Reference**: `.claude/lib/workflow-initialization.sh` lines 312-344 (dynamic allocation), `.claude/specs/678_coordinate_haiku_classification/reports/002_phase0_and_capture_improvements.md` (Phase 0 pre-allocation analysis)

#### 2.3 Pattern Matching Elimination

Spec 678 Phase 5 deleted all pattern matching for classification:

**Deleted Code** (coordinate.md lines 402-414, removed in commit 0000bec4):
```bash
# OLD: Pattern matching for research complexity (FALSE POSITIVE RISK)
RESEARCH_COMPLEXITY=2

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "integrate|refactor"; then
  RESEARCH_COMPLEXITY=3
fi

if echo "$WORKFLOW_DESCRIPTION" | grep -Eiq "multiple|several|various"; then
  RESEARCH_COMPLEXITY=4
fi
```

**Replaced With**: RESEARCH_COMPLEXITY loaded from workflow state (set during sm_init by Haiku classification)

**False Positive Example Eliminated**:
- Input: "research the refactor command"
- Old pattern: RESEARCH_COMPLEXITY=3 (matches "refactor")
- Haiku classification: RESEARCH_COMPLEXITY=1 (correctly identifies simple research task)

**File Reference**: Git commit 0000bec4 diff shows 13 lines deleted from coordinate.md

### 3. Differences from Spec 670 (Original LLM Integration)

#### 3.1 Scope of Spec 670

Spec 670 introduced LLM-based classification but intentionally limited scope:

**Spec 670 Deliverables**:
- `detect_workflow_scope()` function using Haiku for workflow type detection
- Hybrid mode with regex fallback
- Intent-focused prompt to avoid keyword false positives
- 95%+ accuracy for workflow type classification

**What Spec 670 Did NOT Cover**:
- Research complexity determination (left as pattern matching)
- Subtopic identification (used generic "Topic N" names)
- Comprehensive classification in single call

**Rationale**: Incremental deployment strategy to validate LLM reliability before expanding scope.

**File Reference**: Git history shows Spec 670 commits focused on `detect_workflow_scope()` function only, `.claude/specs/678_coordinate_haiku_classification/reports/001_current_state_analysis.md` (Gap Analysis section)

#### 3.2 Spec 678 Extensions

Spec 678 extended Spec 670's foundation in four dimensions:

**1. Comprehensive Classification**:
- Single LLM call returns all three dimensions (scope, complexity, subtopics)
- Replaces two separate operations (LLM scope + pattern complexity)
- ~450-500ms total vs ~405ms (Spec 670 + patterns)

**2. Descriptive Subtopics**:
- Haiku generates contextual topic names based on workflow description
- Fallback generates descriptive names from plan analysis
- Research agents receive meaningful context instead of "Topic 1", "Topic 2"

**3. Dynamic Path Allocation**:
- sm_init() returns RESEARCH_COMPLEXITY for use in path allocation
- initialize_workflow_paths() allocates exact count needed
- Eliminates fixed capacity (4) vs dynamic usage (1-4) tension

**4. Clean Break Architecture**:
- Deleted `detect_workflow_scope()` wrapper function entirely
- All callers updated to use `classify_workflow_comprehensive()`
- Zero deprecation period or compatibility shims

**Performance Comparison**:
- Spec 670: ~400ms (Haiku scope) + ~5ms (pattern complexity) = ~405ms
- Spec 678: ~450-500ms (single comprehensive Haiku call)
- Net overhead: ~10-20% slower but eliminates false positives

**File Reference**: `.claude/specs/678_coordinate_haiku_classification/SUMMARY.md` (Architecture Changes section), `.claude/specs/678_coordinate_haiku_classification/CLEAN_BREAK_REVISION.md` (clean break rationale)

### 4. Key Technical Decisions and Tradeoffs

#### 4.1 Model Selection: Haiku 4.5

**Decision**: Use Haiku 4.5 for comprehensive classification (not Sonnet)

**Cost Analysis**:
- Haiku: ~500 tokens × 2 calls/day × 30 days = 30K tokens/month = $0.024/month
- Sonnet: Same usage = $0.090/month (3.75x more expensive)

**Quality Requirements**:
- Workflow type accuracy: 95%+ required (mission-critical) - Haiku achieves this
- Subtopic quality: 85%+ acceptable (user can refine) - Haiku sufficient
- Research complexity: 90%+ required - Haiku adequate

**Rationale**: Haiku proven reliable in Spec 670 (95%+ scope accuracy). For classification tasks requiring semantic understanding but not complex reasoning, Haiku offers optimal cost/quality tradeoff. If subtopic quality drops below 85% in production, upgrade to Sonnet.

**File Reference**: `.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md` lines 67-86 (Model Selection section)

#### 4.2 Hybrid Classification with Automatic Fallback

**Decision**: Default to hybrid mode (LLM first, regex fallback on failure)

**Three Modes Supported**:
1. `hybrid` (default): LLM classification with automatic regex fallback
2. `llm-only`: Fail-fast on LLM errors (for testing/validation)
3. `regex-only`: Traditional pattern matching (for offline/no-API scenarios)

**Fallback Trigger Conditions**:
- LLM invocation timeout (>10 seconds)
- Low confidence score (<0.7)
- JSON parsing failure
- Network/API errors

**Fallback Implementation**:
```bash
# workflow-scope-detection.sh lines 114-141
fallback_comprehensive_classification() {
  local scope=$(classify_workflow_regex "$workflow_desc")        # Regex scope
  local complexity=$(infer_complexity_from_keywords "$workflow_desc")  # Heuristic
  local subtopics=$(generate_generic_topics "$complexity")       # Generic names

  jq -n --arg scope "$scope" --argjson complexity "$complexity" \
    --argjson subtopics "$subtopics" \
    '{"workflow_type": $scope, "confidence": 0.6, "research_complexity": $complexity, "subtopics": $subtopics}'
}
```

**Zero Operational Risk**: Regex fallback ensures 100% availability even if Haiku API unavailable or slow.

**File Reference**: `.claude/lib/workflow-scope-detection.sh` lines 61-106 (hybrid mode implementation), lines 114-189 (fallback functions)

#### 4.3 Descriptive Topic Fallback

**Decision**: Generate descriptive topic names when Haiku returns generic fallback

**Problem**: When LLM classification fails or returns low confidence, subtopics default to generic "Topic 1", "Topic 2", etc. This provides no context to research agents.

**Solution** (Spec 683 Phase 2):
```bash
# workflow-state-machine.sh lines 388-416
if echo "$RESEARCH_TOPICS_JSON" | jq -e '.[] | select(test("^Topic [0-9]+$"))'; then
  case "$WORKFLOW_SCOPE" in
    research-and-revise)
      # Extract plan paths and generate topics from their content
      DESCRIPTIVE_TOPICS=$(generate_descriptive_topics_from_plans "$workflow_desc" "$RESEARCH_COMPLEXITY")
      ;;
    research-and-plan|full-implementation)
      # Analyze workflow description for key concepts
      DESCRIPTIVE_TOPICS=$(generate_descriptive_topics_from_description "$workflow_desc" "$RESEARCH_COMPLEXITY")
      ;;
  esac
  RESEARCH_TOPICS_JSON="$DESCRIPTIVE_TOPICS"
fi
```

**Example Transformation**:
- Generic fallback: `["Topic 1", "Topic 2", "Topic 3", "Topic 4"]`
- After descriptive fallback: `["Haiku classification implementation architecture", "Coordinate command integration points", "Performance characteristics and metrics", "Optimization opportunities and lessons learned"]`

**Implementation Details**:
- `generate_descriptive_topics_from_plans()`: Extracts plan titles and target topic names from file paths
- `generate_descriptive_topics_from_description()`: Extracts key terms (nouns/verbs) from workflow description
- Generates 2-4 topics matching RESEARCH_COMPLEXITY

**File Reference**: `.claude/lib/workflow-state-machine.sh` lines 214-313 (descriptive topic generation functions), commit 585708cd (implementation)

#### 4.4 Clean Break vs Backward Compatibility

**Decision**: Delete `detect_workflow_scope()` entirely (no wrapper, no deprecation period)

**Rationale**:
- Code analysis (grep entire codebase) revealed zero non-coordinate callers in production
- All references found in .backup files, test files, or documentation
- User prefers clean-break philosophy per CLAUDE.md: "delete obsolete code immediately after migration"
- Wrapper is unnecessary technical debt

**Impact**:
- Simpler rollback: single commit revert (5 minutes) vs gradual migration (30 minutes)
- No ongoing maintenance burden for compatibility shims
- Clear upgrade path: all callers use `classify_workflow_comprehensive()` consistently

**Alternative Considered**: Maintain `detect_workflow_scope()` wrapper calling new function for backward compatibility
**Rejected Because**: Zero external callers mean no compatibility burden, wrapper adds code complexity for no benefit

**File Reference**: `.claude/specs/678_coordinate_haiku_classification/CLEAN_BREAK_REVISION.md` (rationale), `.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md` lines 167-171 (clean break section)

#### 4.5 Subprocess Isolation Bug (Spec 683 Critical Fix)

**Problem**: Commit 0000bec4 (Spec 678 Phase 5) introduced command substitution pattern that broke variable exports:

```bash
# WRONG (creates subshell):
RESEARCH_COMPLEXITY=$(sm_init "$SAVED_WORKFLOW_DESC" "coordinate")
# sm_init exports only affect subshell, NOT parent shell
# Result: WORKFLOW_SCOPE undefined → initialization failure
```

**Root Cause**: Spec 678 Phase 5 implementer attempted to capture sm_init's return value using command substitution, not realizing this would break the export mechanism that coordinate.md depends on.

**Fix** (Spec 683 Phase 1, commit 1c72e904):
```bash
# CORRECT (runs in parent shell):
sm_init "$SAVED_WORKFLOW_DESC" "coordinate" >/dev/null
# sm_init exports affect parent shell
# RESEARCH_COMPLEXITY and WORKFLOW_SCOPE now available via export
```

**Impact**: All /coordinate invocations were broken between commits 0000bec4 and 1c72e904 (~1 hour window). This was detected immediately via execution trace analysis.

**Prevention**: Updated bash-block-execution-model.md documentation with subprocess isolation patterns and anti-patterns. Added to troubleshooting guide in coordinate-command-guide.md.

**File Reference**: `.claude/specs/683_coordinate_critical_bug_fixes/plans/001_coordinate_bug_fixes.md` lines 24-95 (Root Cause Analysis), `.claude/commands/coordinate.md` lines 163-168 (fixed pattern), `.claude/docs/concepts/bash-block-execution-model.md` (subprocess isolation documentation)

#### 4.6 JSON Escaping for State Persistence

**Problem**: State persistence didn't escape special characters in JSON strings:

```bash
# WRONG:
echo "export RESEARCH_TOPICS_JSON=\"[\"Topic 1\",\"Topic 2\"]\"" >> "$STATE_FILE"
# Results in: export RESEARCH_TOPICS_JSON="["Topic 1","Topic 2"]"
# Bash sees: export 1,Topic (syntax error)
```

**Fix** (Spec 683 Phase 1, commit 1c72e904):
```bash
# state-persistence.sh lines 261-266
local escaped_value="${value//\\/\\\\}"     # \ → \\
escaped_value="${escaped_value//\"/\\\"}"  # " → \"
echo "export ${key}=\"${escaped_value}\"" >> "$STATE_FILE"
```

**Validation**: State files now pass `bash -n` syntax check before sourcing.

**File Reference**: `.claude/lib/state-persistence.sh` lines 261-266 (escaping logic), `.claude/tests/test_coordinate_critical_bugs.sh` lines 22-28 (regression test)

### 5. Impact on Command Agent Optimization (Spec 677)

#### 5.1 Foundation for Agent-Level Optimization

Comprehensive classification provides the foundation for command-level agent optimization by exposing all workflow characteristics in a single operation:

**Classification Data Available to Downstream Systems**:
```bash
WORKFLOW_SCOPE="research-and-plan"           # Determines workflow phases
RESEARCH_COMPLEXITY=2                         # Indicates resource requirements
RESEARCH_TOPICS_JSON='[                       # Provides semantic context
  "Authentication patterns in existing codebase",
  "Security best practices for auth implementation"
]'
```

**Optimization Opportunities** (not yet implemented, future work for Spec 677):

1. **Parallel Research Agent Allocation**:
   - RESEARCH_COMPLEXITY=2 → spawn 2 research agents in parallel
   - Descriptive topics enable targeted research (not generic "Topic 1")
   - 40-60% time savings via wave-based execution (proven in coordinate implementation)

2. **Model Selection by Subtopic Complexity**:
   - Analyze subtopic descriptions to determine model requirements
   - Simple research: Haiku (cost-effective)
   - Complex analysis: Sonnet (higher quality)
   - Cost optimization: use appropriate model tier for each subtask

3. **Resource Prediction**:
   - RESEARCH_COMPLEXITY=4 → allocate more memory/tokens for research phase
   - full-implementation scope → pre-warm testing infrastructure
   - Adaptive resource allocation based on workflow characteristics

**Current State**: Classification data exported and available, but optimization logic not yet implemented. This is future work for Spec 677.

**File Reference**: `.claude/specs/677_and_the_agents_in_claude_agents_in_order_to_rank/` (command agent optimization spec, not yet reviewed for this report)

#### 5.2 Architectural Precedent

The comprehensive classification architecture establishes patterns for command-level intelligence:

**Pattern 1: Single LLM Call for Multiple Dimensions**
- Proven feasible to request multiple classification dimensions in one call
- ~450ms for comprehensive classification vs ~405ms for separate calls
- Marginal performance cost for significant architectural benefit

**Pattern 2: Hybrid LLM + Heuristic Fallback**
- Zero operational risk: automatic fallback ensures 100% availability
- Configurable modes (hybrid/llm-only/regex-only) for testing/production
- Confidence thresholds enable quality control

**Pattern 3: State Machine Integration**
- Classification occurs during sm_init (initialization phase)
- Results persisted to workflow state for bash block isolation
- Downstream phases load from state (no re-classification)

**Applicability to Other Commands**: These patterns can be adopted by /orchestrate, /supervise, and custom orchestrators for workflow-aware optimization.

**File Reference**: `.claude/docs/architecture/state-based-orchestration-overview.md` (state machine patterns), `.claude/docs/concepts/patterns/llm-classification-pattern.md` (LLM classification patterns)

### 6. Testing Infrastructure and Validation

#### 6.1 Test Coverage

Comprehensive test suite covers all classification dimensions:

**Test File**: `.claude/tests/test_coordinate_critical_bugs.sh`
- Test 1: sm_init export behavior (WORKFLOW_SCOPE, RESEARCH_COMPLEXITY available in parent shell)
- Test 2: JSON escaping in workflow state (syntax validation)
- Test 3: Descriptive topic generation (no generic "Topic N" patterns)
- Test 4: research-and-revise topic directory reuse (EXISTING_PLAN_PATH handling)

**Integration Tests** (existing test files):
- `test_coordinate_error_fixes.sh`: 34KB test suite for error handling
- `test_coordinate_state_variables.sh`: 11KB test suite for state persistence
- `test_coordinate_bash_block_fixes_integration.sh`: 11KB test suite for bash block isolation

**Test Output Format**: Standard `✓ PASS` / `✗ FAIL` / `⊘ SKIP` format matching run_all_tests.sh conventions

**File Reference**: `.claude/tests/test_coordinate_critical_bugs.sh` (regression tests), `.claude/tests/run_all_tests.sh` (test runner)

#### 6.2 Validation Checkpoints

Standard 0 (Execution Enforcement) validation checkpoints ensure file creation and state persistence:

**Checkpoint Pattern**:
```bash
# VERIFICATION CHECKPOINT: Verify state variable persisted
verify_state_variable "WORKFLOW_SCOPE" || {
  handle_state_error "CRITICAL: WORKFLOW_SCOPE not persisted to state after sm_init" 1
}
```

**Applied in coordinate.md**:
- Line 192: Verify WORKFLOW_SCOPE persisted after sm_init
- Line 201: Verify EXISTING_PLAN_PATH persisted for research-and-revise workflows
- Line 152: Verify state ID file created successfully

**Purpose**: Fail-fast detection of classification/state persistence failures, not silent fallbacks that hide errors.

**File Reference**: `.claude/commands/coordinate.md` lines 192-204 (verification checkpoints), `.claude/docs/concepts/patterns/verification-fallback.md` (verification pattern documentation)

### 7. Documentation and Troubleshooting

#### 7.1 Updated Documentation

Four documentation files updated to reflect comprehensive classification:

**1. Coordinate Command Guide** (`.claude/docs/guides/coordinate-command-guide.md`):
- Added troubleshooting section for subshell export issues (Issue 5)
- References bash-block-execution-model.md for subprocess patterns
- Documents error-handling.sh usage for proper error classification

**2. LLM Classification Pattern** (`.claude/docs/concepts/patterns/llm-classification-pattern.md`):
- Updated with comprehensive classification examples
- Documents three-layer architecture
- Explains hybrid mode and fallback behavior

**3. CLAUDE.md** (state-based orchestration section):
- Updated workflow classification description to reflect comprehensive approach
- Added RESEARCH_COMPLEXITY and RESEARCH_TOPICS_JSON to environment variables
- Cross-references coordinate-command-guide.md

**4. Phase 0 Optimization Guide** (`.claude/docs/guides/phase-0-optimization.md`):
- Clarified what changed (fixed → dynamic allocation)
- Documented what preserved (pre-calculation core optimization)
- Updated with dynamic allocation approach

**File Reference**: Git commit 4f98de9b (documentation updates), `.claude/docs/guides/coordinate-command-guide.md` (troubleshooting section)

#### 7.2 Troubleshooting Patterns

Common issues and solutions documented:

**Issue 1: Variables not available after sm_init**
- Symptom: WORKFLOW_SCOPE or RESEARCH_COMPLEXITY undefined
- Cause: Command substitution creates subshell
- Solution: Call sm_init directly without $()

**Issue 2: State file syntax errors**
- Symptom: Bash syntax error when sourcing state file
- Cause: JSON strings with unescaped quotes
- Solution: Use state-persistence.sh append_workflow_state() function

**Issue 3: Generic topic names in research prompts**
- Symptom: Research agents receive "Topic 1", "Topic 2"
- Cause: LLM fallback to generic names when classification fails
- Solution: Descriptive topic fallback generates contextual names automatically

**Issue 4: Wrong topic directory for research-and-revise**
- Symptom: Reports created in new directory instead of existing plan's directory
- Cause: initialize_workflow_paths() doesn't check for existing plan
- Solution: Pass EXISTING_PLAN_PATH, function detects research-and-revise scope

**File Reference**: `.claude/docs/guides/coordinate-command-guide.md` (Troubleshooting section), `.claude/specs/683_coordinate_critical_bug_fixes/plans/001_coordinate_bug_fixes.md` (bug analysis)

## Recommendations

### 1. Monitor Haiku Classification Accuracy

**Action**: Track classification accuracy metrics over next 30 days
- Workflow type accuracy (target: 95%+)
- Subtopic quality (target: 85%+)
- Research complexity accuracy (target: 90%+)

**If accuracy drops below targets**: Upgrade to Sonnet 4.5 for classification (3.75x cost increase but higher quality)

**Rationale**: Haiku 4.5 proven reliable in Spec 670 (95%+ scope accuracy), but comprehensive classification is more complex. Production validation needed.

### 2. Extend to Other Orchestrators

**Action**: Adopt comprehensive classification pattern in /orchestrate and /supervise

**Benefits**:
- Consistent classification across all orchestration commands
- Shared test infrastructure and validation logic
- Unified troubleshooting and documentation

**Effort**: ~2-3 hours per orchestrator (mostly integration work, libraries already exist)

**Rationale**: Three orchestration commands currently use different classification approaches. Standardization improves maintainability.

### 3. Implement Command Agent Optimization (Spec 677)

**Action**: Use comprehensive classification data for intelligent resource allocation

**Opportunities**:
- Parallel research agent spawning based on RESEARCH_COMPLEXITY
- Model selection by subtopic complexity analysis
- Adaptive resource allocation for memory/token budgets

**Effort**: Estimated 8-12 hours (new functionality, not just refactoring)

**Rationale**: Classification infrastructure now provides foundation for agent-level optimization. Next logical evolution.

### 4. Add Performance Metrics Logging

**Action**: Log classification latency and fallback frequency

**Metrics to Track**:
- Haiku invocation latency (95th percentile)
- Fallback trigger frequency (LLM failures)
- Confidence score distribution

**Purpose**: Detect performance regressions and fallback patterns

**Implementation**: Add to unified-logger.sh with adaptive-planning log format

**Effort**: ~1 hour (extend existing logging infrastructure)

### 5. Validate Clean Break Migration

**Action**: Run comprehensive grep to verify zero references to old function names

**Commands**:
```bash
# Search for detect_workflow_scope references outside backups/tests
grep -r "detect_workflow_scope" .claude/docs/ .claude/lib/ .claude/commands/ \
  | grep -v ".backup" | grep -v "test_" | grep -v "# Historical"

# Expected: Zero references (or only historical markers in documentation)
```

**Purpose**: Confirm clean break complete, no lingering compatibility code

**File Reference**: `.claude/specs/678_coordinate_haiku_classification/CLEAN_BREAK_REVISION.md` (clean break rationale)

### 6. Document Model Selection Rationale in Other Specs

**Action**: Apply model selection analysis pattern to future specs

**Template**: Use Spec 678 model selection section as template:
- Task complexity analysis (simple/medium/complex)
- Cost comparison (Haiku vs Sonnet)
- Quality requirements (accuracy targets)
- Decision rationale with upgrade criteria

**Purpose**: Standardize model selection documentation across all specs

**File Reference**: `.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md` lines 67-86 (model selection section)

## References

### Implementation Files
- `/home/benjamin/.config/.claude/lib/workflow-llm-classifier.sh` (lines 99-200): Comprehensive LLM classification
- `/home/benjamin/.config/.claude/lib/workflow-scope-detection.sh` (lines 50-189): Hybrid classification and fallback
- `/home/benjamin/.config/.claude/lib/workflow-state-machine.sh` (lines 345-416): State machine integration and descriptive fallback
- `/home/benjamin/.config/.claude/lib/workflow-initialization.sh` (lines 312-344): Dynamic path allocation
- `/home/benjamin/.config/.claude/lib/state-persistence.sh` (lines 261-266): JSON escaping fix
- `/home/benjamin/.config/.claude/commands/coordinate.md` (lines 163-168): sm_init integration pattern

### Test Files
- `/home/benjamin/.config/.claude/tests/test_coordinate_critical_bugs.sh`: Regression tests for Spec 683 bug fixes
- `/home/benjamin/.config/.claude/tests/test_coordinate_error_fixes.sh`: Comprehensive error handling tests
- `/home/benjamin/.config/.claude/tests/test_coordinate_state_variables.sh`: State persistence validation

### Documentation Files
- `/home/benjamin/.config/.claude/docs/guides/coordinate-command-guide.md`: Complete coordinate command documentation with troubleshooting
- `/home/benjamin/.config/.claude/docs/concepts/patterns/llm-classification-pattern.md`: LLM classification pattern documentation
- `/home/benjamin/.config/.claude/docs/concepts/bash-block-execution-model.md`: Subprocess isolation patterns
- `/home/benjamin/.config/.claude/docs/guides/phase-0-optimization.md`: Phase 0 pre-calculation optimization
- `/home/benjamin/.config/CLAUDE.md`: Project configuration with state-based orchestration section

### Spec Files
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/plans/001_comprehensive_classification_implementation.md`: Implementation plan (6 phases, 10.5-13.5 hours)
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/001_current_state_analysis.md`: Root cause analysis of Issue 676 and Spec 670 gap
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/reports/002_phase0_and_capture_improvements.md`: Phase 0 pre-allocation tension analysis
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/SUMMARY.md`: Executive summary of Spec 678
- `/home/benjamin/.config/.claude/specs/678_coordinate_haiku_classification/CLEAN_BREAK_REVISION.md`: Clean break migration rationale
- `/home/benjamin/.config/.claude/specs/683_coordinate_critical_bug_fixes/plans/001_coordinate_bug_fixes.md`: Critical bug fixes plan (5 phases)

### Git Commits
- `93c20f09`: Spec 678 Phase 1 - Enhanced Haiku Classifier Library
- `d745c446`: Spec 678 Phase 2 - Comprehensive Classification Function
- `f696550a`: Spec 678 Phase 3 - State Machine Integration with Return Value
- `2d72c5b4`: Spec 678 Phase 4 - Dynamic Path Allocation
- `0000bec4`: Spec 678 Phase 5 - coordinate.md Integration (introduced subprocess bug)
- `1c72e904`: Spec 683 Phase 1 - Fix subprocess export bug and JSON escaping
- `585708cd`: Spec 683 Phase 2 - Descriptive topic name fallback
- `ca6a6227`: Spec 683 Phase 3 - Topic directory detection for research-and-revise
- `4f98de9b`: Spec 683 Phase 5 - Regression tests and troubleshooting guide
